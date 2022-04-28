#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	perk_struct = spawnStruct();
	perk_struct.cost = 1500;
	perk_struct.hint_string = &"ZOMBIE_PERK_QUICKREVIVE";
	perk_struct.perk_bottle = "zombie_perk_bottle_revive";
	perk_struct.perk_shader = "specialty_quickrevive_zombies";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_quickrevive" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_quickrevive" ];
	}
	else 
	{
		perk_struct.precache_func = ::quickrevive_precache;
	}
	perk_struct.clientfield_register = ::quickrevive_register_clientfield;
	perk_struct.clientfield_set = ::quickrevive_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_quickrevive" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_quickrevive" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::quickrevive_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::blank;
	perk_struct.player_thread_take = ::blank;
	perk_struct.alias = "revive";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_quickrevive", perk_struct );
}

quickrevive_register_clientfield()
{
	registerclientfield( "toplayer", "perk_quick_revive", 1, 2, "int" );
}

quickrevive_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_quick_revive", state );
}

quickrevive_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
    use_trigger.script_sound = "mus_perks_revive_jingle";
    use_trigger.script_string = "revive_perk";
    use_trigger.script_label = "mus_perks_revive_sting";
    use_trigger.target = "vending_revive";
    perk_machine.script_string = "revive_perk";
    perk_machine.targetname = "vending_revive";
    if ( isDefined( bump_trigger ) )
    {
        bump_trigger.script_string = "revive_perk";
    }
}

quickrevive_perk_machine_think()
{
	level endon( "stop_quickrevive_logic" );
	machine = getentarray( "vending_revive", "targetname" );
	machine_triggers = getentarray( "vending_revive", "target" );
	machine_model = undefined;
	machine_clip = undefined;
	if ( !is_true( level.zombiemode_using_revive_perk ) )
	{
		return;
	}
	flag_wait( "start_zombie_round_logic" );
	players = get_players();
	solo_mode = 0;
	if ( use_solo_revive() )
	{
		solo_mode = 1;
	}
	start_state = 0;
	start_state = solo_mode;
	while ( 1 )
	{
		machine = getentarray( "vending_revive", "targetname" );
		machine_triggers = getentarray( "vending_revive", "target" );
		for ( i = 0; i < machine.size; i++ )
		{
			if ( flag_exists( "solo_game" ) && flag_exists( "solo_revive" ) && flag( "solo_game" ) && flag( "solo_revive" ) )
			{
				machine[ i ] hide();
			}
			machine[ i ] setmodel( level.machine_assets[ "revive" ].off_model );
			if ( isDefined( level.quick_revive_final_pos ) )
			{
				level.quick_revive_default_origin = level.quick_revive_final_pos;
			}
			if ( !isDefined( level.quick_revive_default_origin ) )
			{
				level.quick_revive_default_origin = machine[ i ].origin;
				level.quick_revive_default_angles = machine[ i ].angles;
			}
			level.quick_revive_machine = machine[ i ];
		}
		array_thread( machine_triggers, ::set_power_on, 0 );
		if ( !is_true( start_state ) )
		{
			level waittill( "revive_on" );
		}
		start_state = 0;
		i = 0;
		while ( i < machine.size )
		{
			if ( isDefined( machine[ i ].classname ) && machine[ i ].classname == "script_model" )
			{
				if ( isDefined( machine[ i ].script_noteworthy ) && machine[ i ].script_noteworthy == "clip" )
				{
					machine_clip = machine[ i ];
					i++;
					continue;
				}
				machine[ i ] setmodel( level.machine_assets[ "revive" ].on_model );
				machine[ i ] playsound( "zmb_perks_power_on" );
				machine[ i ] vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
				machine_model = machine[ i ];
				machine[ i ] thread perk_fx( "revive_light" );
				machine[ i ] notify( "stop_loopsound" );
				machine[ i ] thread play_loop_on_machine();
				if ( isDefined( machine_triggers[ i ] ) )
				{
					machine_clip = machine_triggers[ i ].clip;
				}
				if ( isDefined( machine_triggers[ i ] ) )
				{
					blocker_model = machine_triggers[ i ].blocker_model;
				}
			}
			i++;
		}
		wait_network_frame();
		if ( solo_mode && isDefined( machine_model ) && !is_true( machine_model.ishidden ) )
		{
			machine_model thread revive_solo_fx( machine_clip, blocker_model );
		}
		array_thread( machine_triggers, ::set_power_on, 1 );
		if ( isDefined( level.machine_assets[ "revive" ].power_on_callback ) )
		{
			array_thread( machine, level.machine_assets[ "revive" ].power_on_callback );
		}
		level notify( "specialty_quickrevive_power_on" );
		if ( isDefined( machine_model ) )
		{
			machine_model.ishidden = 0;
		}
		notify_str = level waittill_any_return( "revive_off", "revive_hide" );
		should_hide = 0;
		if ( notify_str == "revive_hide" )
		{
			should_hide = 1;
		}
		if ( isDefined( level.machine_assets[ "revive" ].power_off_callback ) )
		{
			array_thread( machine, level.machine_assets[ "revive" ].power_off_callback );
		}
		for ( i = 0; i < machine.size; i++ )
		{
			if ( isDefined( machine[ i ].classname ) && machine[ i ].classname == "script_model" )
			{
				machine[ i ] turn_perk_off( should_hide );
			}
		}
	}
}

quickrevive_precache()
{
    precacheitem( "zombie_perk_bottle_revive" );
    precacheshader( "specialty_quickrevive_zombies" );
    precachemodel( "zombie_vending_revive" );
    precachemodel( "zombie_vending_revive_on" );
    precachestring( &"ZOMBIE_PERK_QUICKREVIVE" );
    level._effect[ "revive_light" ] = loadfx( "misc/fx_zombie_cola_revive_on" );
    level._effect[ "revive_light_flicker" ] = loadfx( "maps/zombie/fx_zmb_cola_revive_flicker" );
    level.machine_assets[ "specialty_quickrevive" ] = spawnstruct();
    level.machine_assets[ "specialty_quickrevive" ].off_model = "zombie_vending_revive";
    level.machine_assets[ "specialty_quickrevive" ].on_model = "zombie_vending_revive_on";
}

reenable_quickrevive( machine_clip, solo_mode )
{
	if ( isDefined( level.revive_machine_spawned ) && !is_true( level.revive_machine_spawned ) )
	{
		return;
	}
	wait 0.1;
	power_state = 0;
	if ( is_true( solo_mode ) )
	{
		power_state = 1;
		should_pause = 1;
		players = get_players();
		foreach ( player in players )
		{
			if ( isdefined( player.lives ) && player.lives > 0 && power_state )
			{
				should_pause = 0;
			}
			if ( isdefined( player.lives ) && player.lives < 1 )
			{
				should_pause = 1;
			}
		}
		if ( should_pause )
		{
			perk_pause( "specialty_quickrevive" );
		}
		else
		{
			perk_unpause( "specialty_quickrevive" );
		}
		if ( is_true( level.solo_revive_init ) && flag( "solo_revive" ) )
		{
			disable_quickrevive( machine_clip );
			return;
		}
		update_quickrevive_power_state( 1 );
		unhide_quickrevive();
		restart_quickrevive();
		level notify( "revive_off" );
		wait 0.1;
		level notify( "stop_quickrevive_logic" );
	}
	else
	{
		if ( !is_true( level._dont_unhide_quickervive_on_hotjoin ) )
		{
			unhide_quickrevive();
			level notify( "revive_off" );
			wait 0.1;
		}
		level notify( "revive_hide" );
		level notify( "stop_quickrevive_logic" );
		restart_quickrevive();
		if ( flag( "power_on" ) )
		{
			power_state = 1;
		}
		update_quickrevive_power_state( power_state );
	}
	level thread turn_revive_on();
	if ( power_state )
	{
		perk_unpause( "specialty_quickrevive" );
		level notify( "revive_on" );
		wait 0.1;
		level notify( "specialty_quickrevive_power_on" );
	}
	else
	{
		perk_pause( "specialty_quickrevive" );
	}
	if ( !is_true( solo_mode ) )
	{
		return;
	}
	should_pause = 1;
	players = get_players();
	foreach ( player in players )
	{
		if ( !is_player_valid( player ) )
		{
			continue;
		}
		if ( player hasperk("specialty_quickrevive" ) )
		{
			if ( !isdefined( player.lives ) )
			{
				player.lives = 0;
			}
			if ( !isdefined( level.solo_lives_given ) )
			{
				level.solo_lives_given = 0;
			}
			level.solo_lives_given++;
			player.lives++;
			if ( isdefined( player.lives ) && player.lives > 0 && power_state )
			{
				should_pause = 0;
			}
			should_pause = 1;
		}
	}
	if ( should_pause )
	{
		perk_pause( "specialty_quickrevive" );
	}
	else
	{
		perk_unpause( "specialty_quickrevive" );
	}
}

update_quickrevive_power_state( poweron )
{
	foreach ( item in level.powered_items )
	{
		if ( isdefined( item.target ) && isdefined( item.target.script_noteworthy ) && item.target.script_noteworthy == "specialty_quickrevive" )
		{
			if ( item.power && !poweron )
			{
				if ( !isdefined( item.powered_count ) )
				{
					item.powered_count = 0;
				}
				else if ( item.powered_count > 0 )
				{
					item.powered_count--;
				}
			}
			else if ( !item.power && poweron )
			{
				if ( !isdefined( item.powered_count ) )
				{
					item.powered_count = 0;
				}
				item.powered_count++;
			}
			if ( !isdefined( item.depowered_count ) )
			{
				item.depowered_count = 0;
			}
			item.power = poweron;
		}
	}
}

restart_quickrevive()
{
	triggers = getentarray( "zombie_vending", "targetname" );
	foreach ( trigger in triggers )
	{
		if ( trigger.script_noteworthy == "specialty_quickrevive" || trigger.script_noteworthy == "specialty_quickrevive_upgrade" )
		{
			trigger notify( "stop_quickrevive_logic" );
			trigger thread vending_trigger_think();
			trigger trigger_on();
		}
	}
}

disable_quickrevive( machine_clip )
{
	if ( is_true( level.solo_revive_init ) && flag( "solo_revive" ) && isDefined( level.quick_revive_machine ) )
	{
		triggers = getentarray( "zombie_vending", "targetname" );
		foreach ( trigger in triggers )
		{
			if ( !isdefined( trigger.script_noteworthy ) )
			{
				continue;
			}
			if ( trigger.script_noteworthy == "specialty_quickrevive" || trigger.script_noteworthy == "specialty_quickrevive_upgrade" )
			{
				trigger trigger_off();
			}
		}
		foreach ( item in level.powered_items )
		{
			if ( isdefined( item.target ) && isdefined( item.target.script_noteworthy ) && item.target.script_noteworthy == "specialty_quickrevive" )
			{
				item.power = 1;
				item.self_powered = 1;
			}
		}
		if ( isDefined( level.quick_revive_machine.original_pos ) )
		{
			level.quick_revive_default_origin = level.quick_revive_machine.original_pos;
			level.quick_revive_default_angles = level.quick_revive_machine.original_angles;
		}
		move_org = level.quick_revive_default_origin;
		if ( isDefined( level.quick_revive_linked_ent ) )
		{
			move_org = level.quick_revive_linked_ent.origin;
			if ( isDefined( level.quick_revive_linked_ent_offset ) )
			{
				move_org += level.quick_revive_linked_ent_offset;
			}
			level.quick_revive_machine unlink();
		}
		level.quick_revive_machine moveto( move_org + vectorScale( ( 0, 0, 1 ), 40 ), 3 );
		direction = level.quick_revive_machine.origin;
		direction = ( direction[ 1 ], direction[ 0 ], 0 );
		if ( direction[ 1 ] < 0 || direction[ 0 ] > 0 && direction[ 1 ] > 0 )
		{
			direction = ( direction[ 0 ], direction[ 1 ] * -1, 0 );
		}
		else
		{
			if ( direction[ 0 ] < 0 )
			{
				direction = ( direction[ 0 ] * -1, direction[ 1 ], 0 );
			}
		}
		level.quick_revive_machine vibrate( direction, 10, 0.5, 4 );
		level.quick_revive_machine waittill( "movedone" );
		level.quick_revive_machine hide();
		level.quick_revive_machine.ishidden = 1;
		if ( isDefined( level.quick_revive_machine_clip ) )
		{
			level.quick_revive_machine_clip connectpaths();
			level.quick_revive_machine_clip trigger_off();
		}
		playfx( level._effect[ "poltergeist" ], level.quick_revive_machine.origin );
		if ( isDefined( level.quick_revive_trigger ) && isDefined( level.quick_revive_trigger.blocker_model ) )
		{
			level.quick_revive_trigger.blocker_model show();
		}
		level notify( "revive_hide" );
	}
}

unhide_quickrevive()
{
	while ( players_are_in_perk_area( level.quick_revive_machine ) )
	{
		wait 0.1;
	}
	if ( isDefined( level.quick_revive_machine_clip ) )
	{
		level.quick_revive_machine_clip trigger_on();
		level.quick_revive_machine_clip disconnectpaths();
	}
	if ( isDefined( level.quick_revive_final_pos ) )
	{
		level.quick_revive_machine.origin = level.quick_revive_final_pos;
	}
	playfx( level._effect[ "poltergeist" ], level.quick_revive_machine.origin );
	if ( isDefined( level.quick_revive_trigger ) && isDefined( level.quick_revive_trigger.blocker_model ) )
	{
		level.quick_revive_trigger.blocker_model hide();
	}
	level.quick_revive_machine show();
	if ( isDefined( level.quick_revive_machine.original_pos ) )
	{
		level.quick_revive_default_origin = level.quick_revive_machine.original_pos;
		level.quick_revive_default_angles = level.quick_revive_machine.original_angles;
	}
	direction = level.quick_revive_machine.origin;
	direction = ( direction[ 1 ], direction[ 0 ], 0 );
	if ( direction[ 1 ] < 0 || direction[ 0 ] > 0 && direction[ 1 ] > 0 )
	{
		direction = ( direction[ 0 ], direction[ 1 ] * -1, 0 );
	}
	else
	{
		if ( direction[ 0 ] < 0 )
		{
			direction = ( direction[ 0 ] * -1, direction[ 1 ], 0 );
		}
	}
	org = level.quick_revive_default_origin;
	if ( isDefined( level.quick_revive_linked_ent ) )
	{
		org = level.quick_revive_linked_ent.origin;
		if ( isDefined( level.quick_revive_linked_ent_offset ) )
		{
			org += level.quick_revive_linked_ent_offset;
		}
	}
	if ( !is_true( level.quick_revive_linked_ent_moves ) && level.quick_revive_machine.origin != org )
	{
		level.quick_revive_machine moveto( org, 3 );
		level.quick_revive_machine vibrate( direction, 10, 0.5, 2.9 );
		level.quick_revive_machine waittill( "movedone" );
		level.quick_revive_machine.angles = level.quick_revive_default_angles;
	}
	else
	{
		if ( isDefined( level.quick_revive_linked_ent ) )
		{
			org = level.quick_revive_linked_ent.origin;
			if ( isDefined( level.quick_revive_linked_ent_offset ) )
			{
				org += level.quick_revive_linked_ent_offset;
			}
			level.quick_revive_machine.origin = org;
		}
		level.quick_revive_machine vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
	}
	if ( isDefined( level.quick_revive_linked_ent ) )
	{
		level.quick_revive_machine linkto( level.quick_revive_linked_ent );
	}
	level.quick_revive_machine.ishidden = 0;
}

use_solo_revive()
{
	if ( isDefined( level.using_solo_revive ) )
	{
		return level.using_solo_revive;
	}
	solo_mode = 0;
	if ( getPlayers().size == 1 || is_true( level.force_solo_quick_revive ) )
	{
		solo_mode = 1;
	}
	level.using_solo_revive = solo_mode;
	return solo_mode;
}

revive_solo_fx( machine_clip, blocker_model )
{
	if ( level flag_exists( "solo_revive" ) && flag( "solo_revive" ) && !flag( "solo_game" ) )
	{
		return;
	}
	if ( isDefined( machine_clip ) )
	{
		level.quick_revive_machine_clip = machine_clip;
	}
	if ( !isDefined( level.solo_revive_init ) )
	{
		level.solo_revive_init = 1;
		flag_init( "solo_revive" );
	}
	level notify( "revive_solo_fx" );
	level endon( "revive_solo_fx" );
	self endon( "death" );
	flag_wait( "solo_revive" );
	if ( isDefined( level.revive_solo_fx_func ) )
	{
		level thread [[ level.revive_solo_fx_func ]]();
	}
	wait 2;
	self playsound( "zmb_box_move" );
	playsoundatposition( "zmb_whoosh", self.origin );
	if ( isDefined( self._linked_ent ) )
	{
		self unlink();
	}
	self moveto( self.origin + vectorScale( ( 0, 0, 1 ), 40 ), 3 );
	if ( isDefined( level.custom_vibrate_func ) )
	{
		[[ level.custom_vibrate_func ]]( self );
	}
	else
	{
		direction = self.origin;
		direction = ( direction[ 1 ], direction[ 0 ], 0 );
		if ( direction[ 1 ] < 0 || direction[ 0 ] > 0 && direction[ 1 ] > 0 )
		{
			direction = ( direction[ 0 ], direction[ 1 ] * -1, 0 );
		}
		else
		{
			if ( direction[ 0 ] < 0 )
			{
				direction = ( direction[ 0 ] * -1, direction[ 1 ], 0 );
			}
		}
		self vibrate( direction, 10, 0.5, 5 );
	}
	self waittill( "movedone" );
	playfx( level._effect[ "poltergeist" ], self.origin );
	playsoundatposition( "zmb_box_poof", self.origin );
	level clientnotify( "drb" );
	if ( isDefined( self.fx ) )
	{
		self.fx unlink();
		self.fx delete();
	}
	if ( isDefined( machine_clip ) )
	{
		machine_clip trigger_off();
		machine_clip connectpaths();
	}
	if ( isDefined( blocker_model ) )
	{
		blocker_model show();
	}
	level notify( "revive_hide" );
}

solo_revive_buy_trigger_move( revive_trigger_noteworthy )
{
	self endon( "death" );
	revive_perk_triggers = getentarray( revive_trigger_noteworthy, "script_noteworthy" );
	foreach ( revive_perk_trigger in revive_perk_triggers )
	{
		self thread solo_revive_buy_trigger_move_trigger( revive_perk_trigger );
	}
}

solo_revive_buy_trigger_move_trigger( revive_perk_trigger )
{
	self endon( "death" );
	revive_perk_trigger setinvisibletoplayer( self );
	if ( level.solo_lives_given >= 3 )
	{
		revive_perk_trigger trigger_off();
		if ( isDefined( level._solo_revive_machine_expire_func ) )
		{
			revive_perk_trigger [[ level._solo_revive_machine_expire_func ]]();
		}
		return;
	}
	while ( self.lives > 0 )
	{
		wait 0.1;
	}
	revive_perk_trigger setvisibletoplayer( self );
}