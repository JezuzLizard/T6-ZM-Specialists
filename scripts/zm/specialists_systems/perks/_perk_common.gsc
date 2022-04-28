#include maps\mp\_utility; 
#include common_scripts\utility; 
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_unitrigger;

init_override()
{
    level.additionalprimaryweapon_limit = 3;
    level.perk_purchase_limit = 4;

    if ( !level.createfx_enabled )
        perks_register_clientfield();

    if ( !level.enable_magic )
        return;

    initialize_custom_perk_arrays();
    perk_machine_spawn_init();
    vending_weapon_upgrade_trigger = [];
    vending_triggers = getentarray( "zombie_vending", "targetname" );

    for ( i = 0; i < vending_triggers.size; i++ )
    {
        if ( isdefined( vending_triggers[i].script_noteworthy ) && vending_triggers[i].script_noteworthy == "specialty_weapupgrade" )
        {
            vending_weapon_upgrade_trigger[vending_weapon_upgrade_trigger.size] = vending_triggers[i];
            arrayremovevalue( vending_triggers, vending_triggers[i] );
        }
    }

    old_packs = getentarray( "zombie_vending_upgrade", "targetname" );

    for ( i = 0; i < old_packs.size; i++ )
        vending_weapon_upgrade_trigger[vending_weapon_upgrade_trigger.size] = old_packs[i];

    flag_init( "pack_machine_in_use" );

    if ( vending_triggers.size < 1 )
        return;

    if ( vending_weapon_upgrade_trigger.size >= 1 )
        array_thread( vending_weapon_upgrade_trigger, ::vending_weapon_upgrade );

    level.machine_assets = [];

	perk_machine_precaching();
    if ( !isdefined( level.packapunch_timeout ) )
        level.packapunch_timeout = 15;

    set_zombie_var( "zombie_perk_cost", 2000 );
    set_zombie_var( "zombie_perk_juggernaut_health_upgrade", 190 );
    array_thread( vending_triggers, ::vending_trigger_think );
    array_thread( vending_triggers, ::electric_perks_dialog );
	perks = getArrayKeys( level._custom_perks );
	if ( perks.size > 0 )
	{
		for ( i = 0; i < perks.size; i++ )
		{
			level thread perk_machine_think( perks[ i ] );
		}
	}

    if ( isdefined( level._custom_turn_packapunch_on ) )
        level thread [[ level._custom_turn_packapunch_on ]]();
    else
        level thread turn_packapunch_on();
	level.max_perk_tiers = 4;
}

perk_machine_precaching()
{
	if ( level._custom_perks.size > 0 )
	{
		a_keys = getarraykeys( level._custom_perks );
		for ( i = 0; i < a_keys.size; i++ )
		{
			if ( isdefined( level._custom_perks[ a_keys[ i ] ].precache_func ) )
			{
				level [[ level._custom_perks[ a_keys[ i ] ].precache_func ]]();
			}
		}
	}
}

perk_machine_spawn_init_override()
{
    match_string = "";
    location = level.scr_zm_map_start_location;

    if ( ( location == "default" || location == "" ) && isdefined( level.default_start_location ) )
        location = level.default_start_location;

    match_string = level.scr_zm_ui_gametype + "_perks_" + location;
    pos = [];

    if ( isdefined( level.override_perk_targetname ) )
        structs = getstructarray( level.override_perk_targetname, "targetname" );
    else
        structs = getstructarray( "zm_perk_machine", "targetname" );

    foreach ( struct in structs )
    {
        if ( isdefined( struct.script_string ) )
        {
            tokens = strtok( struct.script_string, " " );

            foreach ( token in tokens )
            {
                if ( token == match_string )
                    pos[pos.size] = struct;
            }

            continue;
        }

        pos[pos.size] = struct;
    }

    if ( !isdefined( pos ) || pos.size == 0 )
        return;

    precachemodel( "zm_collision_perks1" );

    for ( i = 0; i < pos.size; i++ )
    {
        perk = pos[i].script_noteworthy;

        if ( isdefined( perk ) && isdefined( pos[i].model ) )
        {
            use_trigger = spawn( "trigger_radius_use", pos[i].origin + vectorscale( ( 0, 0, 1 ), 30.0 ), 0, 40, 70 );
            use_trigger.targetname = "zombie_vending";
            use_trigger.script_noteworthy = perk;
            use_trigger triggerignoreteam();
            perk_machine = spawn( "script_model", pos[i].origin );
            perk_machine.angles = pos[i].angles;
            perk_machine setmodel( pos[i].model );

            if ( isdefined( level._no_vending_machine_bump_trigs ) && level._no_vending_machine_bump_trigs )
                bump_trigger = undefined;
            else
            {
                bump_trigger = spawn( "trigger_radius", pos[i].origin, 0, 35, 64 );
                bump_trigger.script_activated = 1;
                bump_trigger.script_sound = "zmb_perks_bump_bottle";
                bump_trigger.targetname = "audio_bump_trigger";

                if ( perk != "specialty_weapupgrade" )
                    bump_trigger thread thread_bump_trigger();
            }

            collision = spawn( "script_model", pos[i].origin, 1 );
            collision.angles = pos[i].angles;
            collision setmodel( "zm_collision_perks1" );
            collision.script_noteworthy = "clip";
            collision disconnectpaths();
            use_trigger.clip = collision;
            use_trigger.machine = perk_machine;
            use_trigger.bump = bump_trigger;
            if ( isdefined( pos[i].blocker_model ) )
                use_trigger.blocker_model = pos[i].blocker_model;
            if ( isdefined( pos[i].script_int ) )
                perk_machine.script_int = pos[i].script_int;
            if ( isdefined( pos[i].turn_on_notify ) )
                perk_machine.turn_on_notify = pos[i].turn_on_notify;
            if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].perk_machine_set_kvps ) )
                [[ level._custom_perks[perk].perk_machine_set_kvps ]]( use_trigger, perk_machine, bump_trigger, collision );
        }
    }
}

vending_trigger_think_override()
{
	self endon( "death" );
    wait 0.01;
    perk = self.script_noteworthy;
    solo = 0;
    start_on = 0;
    level.revive_machine_is_solo = 0;

    if ( isdefined( perk ) && ( perk == "specialty_quickrevive" || perk == "specialty_quickrevive_upgrade" ) )
    {
        flag_wait( "start_zombie_round_logic" );
        solo = use_solo_revive();
        self endon( "stop_quickrevive_logic" );
        level.quick_revive_trigger = self;

        if ( solo )
        {
            if ( !is_true( level.revive_machine_is_solo ) )
            {
                start_on = 1;
                players = get_players();

                foreach ( player in players )
                {
                    if ( !isdefined( player.lives ) )
                        player.lives = 0;
                }

                level maps\mp\zombies\_zm::set_default_laststand_pistol( 1 );
            }

            level.revive_machine_is_solo = 1;
        }
    }

    self sethintstring( &"ZOMBIE_NEED_POWER" );
    self setcursorhint( "HINT_NOICON" );
    self usetriggerrequirelookat();
    cost = level.zombie_vars["zombie_perk_cost"];
    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].cost ) )
        cost = level._custom_perks[perk].cost;

    self.cost = cost;

    if ( !start_on )
    {
        notify_name = perk + "_power_on";

        level waittill( notify_name );
    }

    start_on = 0;

    if ( !isdefined( level._perkmachinenetworkchoke ) )
        level._perkmachinenetworkchoke = 0;
    else
        level._perkmachinenetworkchoke++;

    for ( i = 0; i < level._perkmachinenetworkchoke; i++ )
        wait_network_frame();

    self thread maps\mp\zombies\_zm_audio::perks_a_cola_jingle_timer();
    self thread check_player_has_perk( perk );
    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].hint_string ) )
        self sethintstring( level._custom_perks[perk].hint_string, cost );

    for (;;)
    {
        self waittill( "trigger", player );

        index = maps\mp\zombies\_zm_weapons::get_player_index( player );

        if ( player maps\mp\zombies\_zm_laststand::player_is_in_laststand() || isdefined( player.intermission ) && player.intermission )
            continue;

        if ( player in_revive_trigger() )
            continue;

        if ( !player maps\mp\zombies\_zm_magicbox::can_buy_weapon() )
        {
            wait 0.1;
            continue;
        }

        if ( player isthrowinggrenade() )
        {
            wait 0.1;
            continue;
        }

        if ( player isswitchingweapons() )
        {
            wait 0.1;
            continue;
        }

        if ( player.is_drinking > 0 )
        {
            wait 0.1;
            continue;
        }

        if ( player hasperk( perk ) && ( player current_perk_tier( perk_str ) >= level.max_perk_tiers ) )
        {
            self playsound( "deny" );
            player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 1 );
            continue;
        }

        if ( isdefined( level.custom_perk_validation ) )
        {
            valid = self [[ level.custom_perk_validation ]]( player );

            if ( !valid )
                continue;
        }

        current_cost = cost;

        if ( player maps\mp\zombies\_zm_pers_upgrades_functions::is_pers_double_points_active() )
            current_cost = player maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_double_points_cost( current_cost );

        if ( player.score < current_cost )
        {
            self playsound( "evt_perk_deny" );
            player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
            continue;
		}
        sound = "evt_bottle_dispense";
        playsoundatposition( sound, self.origin );
        player maps\mp\zombies\_zm_score::minus_to_player_score( current_cost, 1 );
        player.perk_purchased = perk;
        self thread maps\mp\zombies\_zm_audio::play_jingle_or_stinger( self.script_label );
        self thread vending_trigger_post_think( player, perk );
    }
}

vending_trigger_post_think( player, perk )
{
    player endon( "disconnect" );
    player endon( "end_game" );
    player endon( "perk_abort_drinking" );
    gun = player perk_give_bottle_begin( perk );
    evt = player waittill_any_return( "fake_death", "death", "player_downed", "weapon_change_complete" );
    if ( evt == "weapon_change_complete" )
        player thread wait_give_perk( perk, 1 );
    player perk_give_bottle_end( gun, perk );
    if ( player maps\mp\zombies\_zm_laststand::player_is_in_laststand() || isdefined( player.intermission ) && player.intermission )
        return;
    player notify( "burp" );
    if ( isdefined( level.perk_bought_func ) )
        player [[ level.perk_bought_func ]]( perk );
    player.perk_purchased = undefined;
}

give_perk_override( perk, bought )
{
    self setperk( perk );
    self.num_perks++;
    if ( isdefined( bought ) && bought )
    {
        self maps\mp\zombies\_zm_audio::playerexert( "burp" );

        if ( isdefined( level.remove_perk_vo_delay ) && level.remove_perk_vo_delay )
            self maps\mp\zombies\_zm_audio::perk_vox( perk );
        else
            self delay_thread( 1.5, maps\mp\zombies\_zm_audio::perk_vox, perk );

        self setblur( 4, 0.1 );
        wait 0.1;
        self setblur( 0, 0.1 );
        self notify( "perk_bought", perk );
    }
    self perk_set_max_health_if_jugg( perk, 1, 0 );
    if ( perk == "specialty_scavenger" )
        self.hasperkspecialtytombstone = 1;
    players = getPlayers();
    if ( use_solo_revive() && perk == "specialty_quickrevive" )
    {
        self.lives = 1;
        if ( !isdefined( level.solo_lives_given ) )
            level.solo_lives_given = 0;
        if ( isdefined( level.solo_game_free_player_quickrevive ) )
            level.solo_game_free_player_quickrevive = undefined;
        else
            level.solo_lives_given++;
        if ( level.solo_lives_given >= 3 )
            flag_set( "solo_revive" );
        self thread solo_revive_buy_trigger_move( perk );
    }
    if ( perk == "specialty_finalstand" )
    {
        self.lives = 1;
        self.hasperkspecialtychugabud = 1;
        self notify( "perk_chugabud_activated" );
    }
    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_give ) )
        self thread [[ level._custom_perks[perk].player_thread_give ]]();
    self increment_perk_tier( perk );
    maps\mp\_demo::bookmark( "zm_player_perk", gettime(), self );
    self maps\mp\zombies\_zm_stats::increment_client_stat( "perks_drank" );
    self maps\mp\zombies\_zm_stats::increment_client_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( "perks_drank" );
    if ( !isdefined( self.perk_history ) )
        self.perk_history = [];
    self notify( "perk_acquired" );
    self thread perk_think( perk );
}

perk_think_override( perk )
{
    perk_str = perk + "_stop";
    result = self waittill_any_return( "fake_death", "death", "player_downed", perk_str );
    do_retain = 1;
    if ( use_solo_revive() && perk == "specialty_quickrevive" )
        do_retain = 0;
    if ( do_retain )
    {
        if ( isdefined( self._retain_perks ) && self._retain_perks )
            return;
        else if ( isdefined( self._retain_perks_array ) && isdefined( self._retain_perks_array[perk] ) && self._retain_perks_array[perk] )
            return;
    }
    self unsetperk( perk );
    self.num_perks--;
    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_take ) )
        self thread [[ level._custom_perks[perk].player_thread_take ]]();
    self perk_hud_destroy( perk );
    self.perk_purchased = undefined;
    if ( isdefined( level.perk_lost_func ) )
        self [[ level.perk_lost_func ]]( perk );
    if ( isdefined( self.perks_active ) && isinarray( self.perks_active, perk ) )
        arrayremovevalue( self.perks_active, perk, 0 );
    self notify( "perk_lost" );
}

perk_hud_create( perk )
{
	if ( !IsDefined( self.perk_hud ) )
	{
		self.perk_hud = [];
	}
	shader = "";
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].perk_shader ) )
	{
		shader = level._custom_perks[ perk ].perk_shader;
	}
	if ( !IsDefined( self.perk_hud[ perk ].perk_icon ) )
	{
		self.perk_hud[ perk ] = spawnStruct();
		self.perk_hud[ perk ].perk_tier = 1;
		perk_icon = create_simple_hud( self );
		perk_icon.foreground = true; 
		perk_icon.sort = 1; 
		perk_icon.hidewheninmenu = false; 
		perk_icon.alignX = "left"; 
		perk_icon.alignY = "bottom";
		perk_icon.horzAlign = "user_left"; 
		perk_icon.vertAlign = "user_bottom";
		perk_icon.x = self.perk_hud.size * 30; 
		perk_icon.y = perk_icon.y - 70; 
		perk_icon.alpha = 1;
		perk_icon SetShader( shader, 24, 24 );
		perk_tier_value = create_simple_hud( self );
		perk_tier_value.foreground = true; 
		perk_tier_value.sort = 1; 
		perk_tier_value.hidewheninmenu = false; 
		perk_tier_value.alignX = "left"; 
		perk_tier_value.alignY = "bottom";
		perk_tier_value.horzAlign = "user_left"; 
		perk_tier_value.vertAlign = "user_bottom";
		perk_tier_value.x = self.perk_hud.size * 32; 
		perk_tier_value.y = perk_tier_value.y - 72; 
		perk_tier_value.alpha = 1;
		perk_tier_value setValue( 1 );
		self.perk_hud[ perk ].tier_value = perk_tier_value;
		self.perk_hud[ perk ].perk_icon = hud;
	}
}

perk_hud_destroy( perk )
{
	self.perk_hud[ perk ].perk_icon destroy_hud();
	self.perk_hud[ perk ].tier_value destroy_hud();
	self.perk_hud[ perk ].perk_icon = undefined;
	self.perk_hud[ perk ].tier_value = undefined;
	self.perk_hud[ perk ].perk_tier = 0;

}

perk_machine_think( str_perk_key )
{
	if ( str_perk_key == "specialty_weapupgrade" )
	{
		scripts/zm/_zm_perk_packapunch::upgrade_machine_think( str_perk_key );
		return;
	}
	while ( 1 )
	{
		machines = getentarray( "vending_" + level._custom_perks[ str_perk_key ].alias, "targetname" );
		machine_triggers = getentarray( "vending_" + level._custom_perks[ str_perk_key ].alias, "target" );
		if ( isDefined( level.machine_assets[ str_perk_key ].off_model ) )
		{
			for ( i = 0; i < machines.size; i++ )
			{
				machines[ i ] setmodel( level.machine_assets[ str_perk_key ].off_model );
			}
		}
		else 
		{
			for ( i = 0; i < machines.size; i++ )
			{
				machines[ i ] setmodel( level.machine_assets[ str_perk_key ].on_model );
			}
		}
		level thread do_initial_power_off_callback( machines, level._custom_perks[ str_perk_key ].alias );
		array_thread( machine_triggers, ::set_power_on, 0 );
		level waittill( level._custom_perks[ str_perk_key ].alias + "_on" );
		for ( i = 0; i < machines.size; i++ )
		{
			machines[ i ] setmodel( level.machine_assets[ str_perk_key ].on_model );
			machines[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
			machines[ i ] playsound( "zmb_perks_power_on" );
			machines[ i ] thread perk_fx( level._custom_perks[ str_perk_key ].alias + "_light" );
			machines[ i ] thread play_loop_on_machine();
		}
		level notify( level._custom_perks[ str_perk_key ].alias + "_power_on" );
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level._custom_perks[ str_perk_key ].power_on_callback ) )
		{
			array_thread( machines, level._custom_perks[ str_perk_key ].power_on_callback );
		}
		level waittill( level._custom_perks[ str_perk_key ].alias + "_off" );
		if ( isDefined( level._custom_perks[ str_perk_key ].power_off_callback ) )
		{
			array_thread( machines, level._custom_perks[ str_perk_key ].power_off_callback );
		}
		array_thread( machines, ::turn_perk_off );
	}
}

increment_perk_tier( perk_str )
{
	if ( isDefined( self.perk_hud[ perk_str ].perk_tier ) && ( self.perk_hud[ perk_str ].perk_tier + 1 ) < level.max_perk_tiers )
	{
		self.perk_hud[ perk_str ].perk_tier++;
	}
	else if ( !isDefined( self.perk_hud[ perk_str ] ) )
	{
		self perk_hud_create( perk_str );
	}
}

decrement_perk_tier( perk_str )
{
	if ( isDefined( self.perk_hud[ perk_str ].perk_tier ) )
	{
		self.perk_hud[ perk_str ].perk_tier--;
		self.perk_hud[ perk ].tier_value setValue( self.perk_hud[ perk_str ].perk_tier );
		if ( self.perk_hud[ perk_str ].perk_tier < 1 )
		{
			self perk_hud_destroy( perk_str );
		}
	}
}

current_perk_tier( perk_str )
{
	return self.perk_hud[ perk_str ].perk_tier;
}