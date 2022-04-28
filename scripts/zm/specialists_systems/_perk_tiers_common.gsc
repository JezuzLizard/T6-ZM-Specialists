#include maps\mp\_utility; 
#include common_scripts\utility; 
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_perks;

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

    switch ( perk )
    {
        case "specialty_armorvest_upgrade":
        case "specialty_armorvest":
            cost = 2500;
            break;
        case "specialty_quickrevive_upgrade":
        case "specialty_quickrevive":
            if ( solo )
                cost = 500;
            else
                cost = 1500;

            break;
        case "specialty_fastreload_upgrade":
        case "specialty_fastreload":
            cost = 3000;
            break;
        case "specialty_rof_upgrade":
        case "specialty_rof":
            cost = 2000;
            break;
        case "specialty_longersprint_upgrade":
        case "specialty_longersprint":
            cost = 2000;
            break;
        case "specialty_deadshot_upgrade":
        case "specialty_deadshot":
            cost = 1500;
            break;
        case "specialty_additionalprimaryweapon_upgrade":
        case "specialty_additionalprimaryweapon":
            cost = 4000;
            break;
    }

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

    switch ( perk )
    {
        case "specialty_armorvest_upgrade":
        case "specialty_armorvest":
            self sethintstring( &"ZOMBIE_PERK_JUGGERNAUT", cost );
            break;
        case "specialty_quickrevive_upgrade":
        case "specialty_quickrevive":
            if ( solo )
                self sethintstring( &"ZOMBIE_PERK_QUICKREVIVE_SOLO", cost );
            else
                self sethintstring( &"ZOMBIE_PERK_QUICKREVIVE", cost );

            break;
        case "specialty_fastreload_upgrade":
        case "specialty_fastreload":
            self sethintstring( &"ZOMBIE_PERK_FASTRELOAD", cost );
            break;
        case "specialty_rof_upgrade":
        case "specialty_rof":
            self sethintstring( &"ZOMBIE_PERK_DOUBLETAP", cost );
            break;
        case "specialty_longersprint_upgrade":
        case "specialty_longersprint":
            self sethintstring( &"ZOMBIE_PERK_MARATHON", cost );
            break;
        case "specialty_deadshot_upgrade":
        case "specialty_deadshot":
            self sethintstring( &"ZOMBIE_PERK_DEADSHOT", cost );
            break;
        case "specialty_additionalprimaryweapon_upgrade":
        case "specialty_additionalprimaryweapon":
            self sethintstring( &"ZOMBIE_PERK_ADDITIONALPRIMARYWEAPON", cost );
            break;
        case "specialty_scavenger_upgrade":
        case "specialty_scavenger":
            self sethintstring( &"ZOMBIE_PERK_TOMBSTONE", cost );
            break;
        case "specialty_finalstand_upgrade":
        case "specialty_finalstand":
            self sethintstring( &"ZOMBIE_PERK_CHUGABUD", cost );
            break;
        default:
            self sethintstring( perk + " Cost: " + level.zombie_vars["zombie_perk_cost"] );
    }

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

        if ( player hasperk( perk ) || player has_perk_paused( perk ) )
        {
            cheat = 0;
/#
            if ( getdvarint( _hash_FA81816F ) >= 5 )
                cheat = 1;
#/
            if ( cheat != 1 )
            {
                self playsound( "deny" );
                player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 1 );
                continue;
            }
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

        if ( player.num_perks >= player get_player_perk_purchase_limit() )
        {
            self playsound( "evt_perk_deny" );
            player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "sigh" );
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
    self perk_hud_create( perk );
    maps\mp\_demo::bookmark( "zm_player_perk", gettime(), self );
    self maps\mp\zombies\_zm_stats::increment_client_stat( "perks_drank" );
    self maps\mp\zombies\_zm_stats::increment_client_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( "perks_drank" );
    if ( !isdefined( self.perk_history ) )
        self.perk_history = [];
    self.perk_history = add_to_array( self.perk_history, perk, 0 );
    if ( !isdefined( self.perks_active ) )
        self.perks_active = [];
    self.perks_active[self.perks_active.size] = perk;
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
    switch ( perk )
    {
        case "specialty_armorvest":
            self setmaxhealth( 100 );
            break;
        case "specialty_additionalprimaryweapon":
            if ( result == perk_str )
                self maps\mp\zombies\_zm::take_additionalprimaryweapon();
            break;
    }
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
	if ( !IsDefined( self.perk_hud[ perk ] ) )
	{
		self.perk_hud[ perk ] = spawnStruct();
		self.perk_hud[ perk ].tier = 1;
	}
	shader = "";
	switch( perk )
	{
	case "specialty_armorvest":
		shader = "specialty_juggernaut_zombies";
		break;
	case "specialty_quickrevive":
		shader = "specialty_quickrevive_zombies";
		break;
	case "specialty_fastreload":
		shader = "specialty_fastreload_zombies";
		break;
	case "specialty_rof":
		shader = "specialty_doubletap_zombies";
		break;
	case "specialty_longersprint":
		shader = "specialty_marathon_zombies";
		break;
	case "specialty_flakjacket":
		shader = "specialty_divetonuke_zombies";
		break;
	case "specialty_deadshot":
		shader = "specialty_ads_zombies"; 
		break;
	case "specialty_additionalprimaryweapon":
		shader = "specialty_extraprimaryweapon_zombies";
		break;
	case "specialty_scavenger":
		shader = "specialty_tombstone_zombies";
		break;
	case "specialty_finalstand":
		shader = "specialty_chugabud_zombies";
		break;
	case "specialty_grenadepulldeath":
		shader = "specialty_electric_cherry_zombie";
		break;
	case "specialty_nomotionsensor":
		shader = "specialty_vulture_zombies";
		break;
	default:
		shader = "";
		break;
	}
	hud = create_simple_hud( self );
	hud.foreground = true; 
	hud.sort = 1; 
	hud.hidewheninmenu = false; 
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_bottom";
	hud.x = self.perk_hud.size * 30; 
	hud.y = hud.y - 70; 
	hud.alpha = 1;
	hud SetShader( shader, 24, 24 );
	self.perk_hud[ perk ] = hud;
}


perk_hud_destroy( perk )
{
	self.perk_hud[ perk ] destroy_hud();
	self.perk_hud[ perk ] = undefined;
}