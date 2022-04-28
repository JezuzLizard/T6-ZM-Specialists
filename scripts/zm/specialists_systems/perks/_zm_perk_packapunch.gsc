#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	perk_struct = spawnStruct();
	perk_struct.cost = 5000;
	perk_struct.hint_string = &"ZOMBIE_PERK_PACKAPUNCH";
	perk_struct.perk_bottle = "zombie_knuckle_crack";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_weapupgrade" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_weapupgrade" ];
	}
	else 
	{
		perk_struct.precache_func = ::packapunch_precache;
	}
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_weapupgrade" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_weapupgrade" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::packapunch_perk_machine_setup;
	}
	perk_struct.alias = "packapunch";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_weapupgrade", perk_struct );
}

packapunch_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
	use_trigger.target = "vending_packapunch";
	use_trigger.script_sound = "mus_perks_packa_jingle";
	use_trigger.script_label = "mus_perks_packa_sting";
	use_trigger.longjinglewait = 1;
	perk_machine.targetname = "vending_packapunch";
	flag_pos = getstruct( pos[ i ].target, "targetname" );
	if ( isDefined( flag_pos ) )
	{
		perk_machine_flag = spawn( "script_model", flag_pos.origin );
		perk_machine_flag.angles = flag_pos.angles;
		perk_machine_flag setmodel( flag_pos.model );
		perk_machine_flag.targetname = "pack_flag";
		perk_machine.target = "pack_flag";
	}
	if ( isDefined( bump_trigger ) )
	{
		bump_trigger.script_string = "perks_rattle";
	}
}

packapunch_precache()
{
	precacheitem( "zombie_knuckle_crack" );
	precachemodel( "p6_anim_zm_buildable_pap" );
	precachemodel( "p6_anim_zm_buildable_pap_on" );
	precachestring( &"ZOMBIE_PERK_PACKAPUNCH" );
	precachestring( &"ZOMBIE_PERK_PACKAPUNCH_ATT" );
	level._effect[ "packapunch_fx" ] = loadfx( "maps/zombie/fx_zombie_packapunch" );
	level.machine_assets[ "specialty_weapupgrade" ] = spawnstruct();
	level.machine_assets[ "specialty_weapupgrade" ].off_model = "p6_anim_zm_buildable_pap";
	level.machine_assets[ "specialty_weapupgrade" ].on_model = "p6_anim_zm_buildable_pap_on";
}

	if ( isDefined( level._custom_turn_packapunch_on ) )
	{
		level thread [[ level._custom_turn_packapunch_on ]]();
	}
	else
	{
		level thread turn_packapunch_on();
	}

third_person_weapon_upgrade( current_weapon, upgrade_weapon, packa_rollers, perk_machine, trigger )
{
	level endon( "Pack_A_Punch_off" );
	trigger endon( "pap_player_disconnected" );
	rel_entity = trigger.perk_machine;
	origin_offset = ( 0, 0, 0 );
	angles_offset = ( 0, 0, 0 );
	origin_base = self.origin;
	angles_base = self.angles;
	if ( isDefined( rel_entity ) )
	{
		if ( isDefined( level.pap_interaction_height ) )
		{
			origin_offset = ( 0, 0, level.pap_interaction_height );
		}
		else
		{
			origin_offset = vectorScale( ( 0, 0, 1 ), 35 );
		}
		angles_offset = vectorScale( ( 0, 1, 0 ), 90 );
		origin_base = rel_entity.origin;
		angles_base = rel_entity.angles;
	}
	else
	{
		rel_entity = self;
	}
	forward = anglesToForward( angles_base + angles_offset );
	interact_offset = origin_offset + ( forward * -25 );
	if ( !isDefined( perk_machine.fx_ent ) )
	{
		perk_machine.fx_ent = spawn( "script_model", origin_base + origin_offset + ( 0, 1, -34 ) );
		perk_machine.fx_ent.angles = angles_base + angles_offset;
		perk_machine.fx_ent setmodel( "tag_origin" );
		perk_machine.fx_ent linkto( perk_machine );
	}
	if ( isDefined( level._effect[ "packapunch_fx" ] ) )
	{
		fx = playfxontag( level._effect[ "packapunch_fx" ], perk_machine.fx_ent, "tag_origin" );
	}
	offsetdw = vectorScale( ( 1, 1, 1 ), 3 );
	weoptions = self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( current_weapon );
	trigger.worldgun = spawn_weapon_model( current_weapon, undefined, origin_base + interact_offset, self.angles, weoptions );
	worldgundw = undefined;
	if ( maps/mp/zombies/_zm_magicbox::weapon_is_dual_wield( current_weapon ) )
	{
		worldgundw = spawn_weapon_model( current_weapon, maps/mp/zombies/_zm_magicbox::get_left_hand_weapon_model_name( current_weapon ), origin_base + interact_offset + offsetdw, self.angles, weoptions );
	}
	trigger.worldgun.worldgundw = worldgundw;
	if ( isDefined( level.custom_pap_move_in ) )
	{
		perk_machine [[ level.custom_pap_move_in ]]( trigger, origin_offset, angles_offset, perk_machine );
	}
	else
	{
		perk_machine pap_weapon_move_in( trigger, origin_offset, angles_offset );
	}
	self playsound( "zmb_perks_packa_upgrade" );
	if ( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles + vectorScale( ( 1, 0, 0 ), 179 ), 0.25, 0, 0 );
	}
	wait 0.35;
	trigger.worldgun delete();
	if ( isDefined( worldgundw ) )
	{
		worldgundw delete();
	}
	wait 3;
	if ( isDefined( self ) )
	{
		self playsound( "zmb_perks_packa_ready" );
	}
	else
	{
		return;
	}
	upoptions = self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( upgrade_weapon );
	trigger.current_weapon = current_weapon;
	trigger.upgrade_name = upgrade_weapon;
	trigger.worldgun = spawn_weapon_model( upgrade_weapon, undefined, origin_base + origin_offset, angles_base + angles_offset + vectorScale( ( 0, 1, 0 ), 90 ), upoptions );
	worldgundw = undefined;
	if ( maps/mp/zombies/_zm_magicbox::weapon_is_dual_wield( upgrade_weapon ) )
	{
		worldgundw = spawn_weapon_model( upgrade_weapon, maps/mp/zombies/_zm_magicbox::get_left_hand_weapon_model_name( upgrade_weapon ), origin_base + origin_offset + offsetdw, angles_base + angles_offset + vectorScale( ( 0, -1, 0 ), 90 ), upoptions );
	}
	trigger.worldgun.worldgundw = worldgundw;
	if ( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles - vectorScale( ( 1, 0, 0 ), 179 ), 0.25, 0, 0 );
	}
	if ( isDefined( level.custom_pap_move_out ) )
	{
		rel_entity thread [[ level.custom_pap_move_out ]]( trigger, origin_offset, interact_offset );
	}
	else
	{
		rel_entity thread pap_weapon_move_out( trigger, origin_offset, interact_offset );
	}
	return trigger.worldgun;
}

can_pack_weapon( weaponname )
{
	if ( weaponname == "riotshield_zm" )
	{
		return 0;
	}
	if ( flag( "pack_machine_in_use" ) )
	{
		return 1;
	}
	weaponname = self get_nonalternate_weapon( weaponname );
	if ( !maps/mp/zombies/_zm_weapons::is_weapon_or_base_included( weaponname ) )
	{
		return 0;
	}
	if ( !self maps/mp/zombies/_zm_weapons::can_upgrade_weapon( weaponname ) )
	{
		return 0;
	}
	return 1;
}

player_use_can_pack_now()
{
	if ( self maps/mp/zombies/_zm_laststand::player_is_in_laststand() || is_true( self.intermission ) || self isthrowinggrenade() )
	{
		return 0;
	}
	if ( !self can_buy_weapon() )
	{
		return 0;
	}
	if ( self hacker_active() )
	{
		return 0;
	}
	if ( !self can_pack_weapon( self getcurrentweapon() ) )
	{
		return 0;
	}
	return 1;
}

vending_machine_trigger_think()
{
	self endon("death");
	self endon("Pack_A_Punch_off");
	while( 1 )
	{
		players = get_players();
		i = 0;
		while ( i < players.size )
		{
			if ( isdefined( self.pack_player ) && self.pack_player != players[ i ] || !players[ i ] player_use_can_pack_now() )
			{
				self setinvisibletoplayer( players[ i ], 1 );
				i++;
				continue;
			}
			self setinvisibletoplayer( players[ i ], 0 );
			i++;
		}
		wait 0.1;
	}
}

vending_weapon_upgrade()
{
	level endon( "Pack_A_Punch_off" );
	wait 0.01;
	perk_machine = getent( self.target, "targetname" );
	self.perk_machine = perk_machine;
	perk_machine_sound = getentarray( "perksacola", "targetname" );
	packa_rollers = spawn( "script_origin", self.origin );
	packa_timer = spawn( "script_origin", self.origin );
	packa_rollers linkto( self );
	packa_timer linkto( self );
	if ( isDefined( perk_machine.target ) )
	{
		perk_machine.wait_flag = getent( perk_machine.target, "targetname" );
	}
	pap_is_buildable = self is_buildable();
	if ( pap_is_buildable )
	{
		self trigger_off();
		perk_machine hide();
		if ( isDefined( perk_machine.wait_flag ) )
		{
			perk_machine.wait_flag hide();
		}
		wait_for_buildable( "pap" );
		self trigger_on();
		perk_machine show();
		if ( isDefined( perk_machine.wait_flag ) )
		{
			perk_machine.wait_flag show();
		}
	}
	self usetriggerrequirelookat();
	self sethintstring( &"ZOMBIE_NEED_POWER" );
	self setcursorhint( "HINT_NOICON" );
	power_off = !self maps/mp/zombies/_zm_power::pap_is_on();
	if ( power_off )
	{
		pap_array = [];
		pap_array[ 0 ] = perk_machine;
		level thread do_initial_power_off_callback( pap_array, "packapunch" );
		level waittill( "Pack_A_Punch_on" );
	}
	self enable_trigger();
	if ( isDefined( level.machine_assets[ "packapunch" ].power_on_callback ) )
	{
		perk_machine thread [[ level.machine_assets[ "packapunch" ].power_on_callback ]]();
	}
	self thread vending_machine_trigger_think();
	perk_machine playloopsound( "zmb_perks_packa_loop" );
	self thread shutoffpapsounds( perk_machine, packa_rollers, packa_timer );
	self thread vending_weapon_upgrade_cost();
	for ( ;; )
	{
		self.pack_player = undefined;
		self waittill( "trigger", player );
		index = maps/mp/zombies/_zm_weapons::get_player_index( player );
		current_weapon = player getcurrentweapon();
		current_weapon = player maps/mp/zombies/_zm_weapons::switch_from_alt_weapon( current_weapon );
		if ( isDefined( level.custom_pap_validation ) )
		{
			valid = self [[ level.custom_pap_validation ]]( player );
			if ( !valid )
			{
				continue;
			}
		}
		if ( player maps/mp/zombies/_zm_magicbox::can_buy_weapon() && !player maps/mp/zombies/_zm_laststand::player_is_in_laststand() && !is_true( player.intermission ) || player isthrowinggrenade() && !player maps/mp/zombies/_zm_weapons::can_upgrade_weapon( current_weapon ) )
		{
			wait 0.1;
			continue;
		}
		if ( is_true( level.pap_moving ) )
		{
			continue;
		}
		if ( player isswitchingweapons() )
		{
			wait 0.1;
			if ( player isswitchingweapons() )
			{
				continue;
			}
		}
		if ( !maps/mp/zombies/_zm_weapons::is_weapon_or_base_included( current_weapon ) )
		{
			continue;
		}
		
		current_cost = self.cost;
		player.restore_ammo = undefined;
		player.restore_clip = undefined;
		player.restore_stock = undefined;
		player_restore_clip_size = undefined;
		player.restore_max = undefined;
		upgrade_as_attachment = will_upgrade_weapon_as_attachment( current_weapon );
		if ( upgrade_as_attachment )
		{
			current_cost = self.attachment_cost;
			player.restore_ammo = 1;
			player.restore_clip = player getweaponammoclip( current_weapon );
			player.restore_clip_size = weaponclipsize( current_weapon );
			player.restore_stock = player getweaponammostock( current_weapon );
			player.restore_max = weaponmaxammo( current_weapon );
		}
		if ( player maps/mp/zombies/_zm_pers_upgrades_functions::is_pers_double_points_active() )
		{
			current_cost = player maps/mp/zombies/_zm_pers_upgrades_functions::pers_upgrade_double_points_cost( current_cost );
		}
		if ( player.score < current_cost ) 
		{
			self playsound( "deny" );
			if ( isDefined( level.custom_pap_deny_vo_func ) )
			{
				player [[ level.custom_pap_deny_vo_func ]]();
			}
			else
			{
				player maps/mp/zombies/_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
			}
			continue;
		}
		
		self.pack_player = player;
		flag_set( "pack_machine_in_use" );
		maps/mp/_demo::bookmark( "zm_player_use_packapunch", getTime(), player );
		player maps/mp/zombies/_zm_stats::increment_client_stat( "use_pap" );
		player maps/mp/zombies/_zm_stats::increment_player_stat( "use_pap" );
		self thread destroy_weapon_in_blackout( player );
		self thread destroy_weapon_on_disconnect( player );
		player maps/mp/zombies/_zm_score::minus_to_player_score( current_cost, 1 );
		sound = "evt_bottle_dispense";
		playsoundatposition( sound, self.origin );
		self thread maps/mp/zombies/_zm_audio::play_jingle_or_stinger( "mus_perks_packa_sting" );
		player maps/mp/zombies/_zm_audio::create_and_play_dialog( "weapon_pickup", "upgrade_wait" );
		self disable_trigger();
		if ( !is_true( upgrade_as_attachment ) )
		{
			player thread do_player_general_vox( "general", "pap_wait", 10, 100 );
		}
		else
		{
			player thread do_player_general_vox( "general", "pap_wait2", 10, 100 );
		}
		player thread do_knuckle_crack();
		self.current_weapon = current_weapon;
		upgrade_name = maps/mp/zombies/_zm_weapons::get_upgrade_weapon( current_weapon, upgrade_as_attachment );
		player third_person_weapon_upgrade( current_weapon, upgrade_name, packa_rollers, perk_machine, self );
		self enable_trigger();
		self sethintstring( &"ZOMBIE_GET_UPGRADED" );
		if ( isDefined( player ) )
		{
			self setinvisibletoall();
			self setvisibletoplayer( player );
			self thread wait_for_player_to_take( player, current_weapon, packa_timer, upgrade_as_attachment );
		}
		self thread wait_for_timeout( current_weapon, packa_timer, player );
		self waittill_any( "pap_timeout", "pap_taken", "pap_player_disconnected" );
		self.current_weapon = "";
		if ( isDefined( self.worldgun ) && isDefined( self.worldgun.worldgundw ) )
		{
			self.worldgun.worldgundw delete();
		}
		if ( isDefined( self.worldgun ) )
		{
			self.worldgun delete();
		}
		if ( is_true( level.zombiemode_reusing_pack_a_punch ) )
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH_ATT", self.cost );
		}
		else
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
		}
		self setvisibletoall();
		self.pack_player = undefined;
		flag_clear( "pack_machine_in_use" );	
	}
}

shutoffpapsounds( ent1, ent2, ent3 )
{
	while ( 1 )
	{
		level waittill( "Pack_A_Punch_off" );
		level thread turnonpapsounds( ent1 );
		ent1 stoploopsound( 0.1 );
		ent2 stoploopsound( 0.1 );
		ent3 stoploopsound( 0.1 );
	}
}

turnonpapsounds( ent )
{
	level waittill( "Pack_A_Punch_on" );
	ent playloopsound( "zmb_perks_packa_loop" );
}

vending_weapon_upgrade_cost()
{
	level endon( "Pack_A_Punch_off" );
	while ( 1 )
	{
		self.cost = 5000;
		self.attachment_cost = 2000;
		if ( is_true( level.zombiemode_reusing_pack_a_punch ) )
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH_ATT", self.cost );
		}
		else
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
		}
		level waittill( "powerup bonfire sale" );
		self.cost = 1000;
		self.attachment_cost = 1000;
		if ( is_true( level.zombiemode_reusing_pack_a_punch ) )
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH_ATT", self.cost );
		}
		else
		{
			self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
		}
		level waittill( "bonfire_sale_off" );
	}
}

wait_for_player_to_take( player, weapon, packa_timer, upgrade_as_attachment )
{
	current_weapon = self.current_weapon;
	upgrade_name = self.upgrade_name;
	upgrade_weapon = upgrade_name;
	self endon( "pap_timeout" );
	level endon( "Pack_A_Punch_off" );
	while ( 1 )
	{
		packa_timer playloopsound( "zmb_perks_packa_ticktock" );
		self waittill( "trigger", trigger_player );
		if ( is_true( level.pap_grab_by_anyone ) )
		{
			player = trigger_player;
		}

		packa_timer stoploopsound( 0.05 );
		if ( trigger_player == player ) //working
		{
			player maps/mp/zombies/_zm_stats::increment_client_stat( "pap_weapon_grabbed" );
			player maps/mp/zombies/_zm_stats::increment_player_stat( "pap_weapon_grabbed" );
			current_weapon = player getcurrentweapon();
			if ( is_player_valid( player ) && !player.is_drinking && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && level.revive_tool != current_weapon && current_weapon != "none" && !player hacker_active() )
			{
				maps/mp/_demo::bookmark( "zm_player_grabbed_packapunch", getTime(), player );
				self notify( "pap_taken" );
				player notify( "pap_taken" );
				player.pap_used = 1;
				if ( !is_true( upgrade_as_attachment ) )
				{
					player thread do_player_general_vox( "general", "pap_arm", 15, 100 );
				}
				else
				{
					player thread do_player_general_vox( "general", "pap_arm2", 15, 100 );
				}
				weapon_limit = get_player_weapon_limit( player );
				player maps/mp/zombies/_zm_weapons::take_fallback_weapon();
				primaries = player getweaponslistprimaries();
				if ( isDefined( primaries ) && primaries.size >= weapon_limit )
				{
					player maps/mp/zombies/_zm_weapons::weapon_give( upgrade_weapon );
				}
				else
				{
					player giveweapon( upgrade_weapon, 0, player maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( upgrade_weapon ) );
					player givestartammo( upgrade_weapon );
				}
				player switchtoweapon( upgrade_weapon );
				if ( is_true( player.restore_ammo ) )
				{
					new_clip = player.restore_clip + ( weaponclipsize( upgrade_weapon ) - player.restore_clip_size );
					new_stock = player.restore_stock + ( weaponmaxammo( upgrade_weapon ) - player.restore_max );
					player setweaponammostock( upgrade_weapon, new_stock );
					player setweaponammoclip( upgrade_weapon, new_clip );
				}
				player.restore_ammo = undefined;
				player.restore_clip = undefined;
				player.restore_stock = undefined;
				player.restore_max = undefined;
				player.restore_clip_size = undefined;
				player maps/mp/zombies/_zm_weapons::play_weapon_vo( upgrade_weapon );
				return;
			}
		}
	}
}

wait_for_timeout( weapon, packa_timer, player )
{
	self endon( "pap_taken" );
	self endon( "pap_player_disconnected" );
	self thread wait_for_disconnect( player );
	wait level.packapunch_timeout;
	self notify( "pap_timeout" );
	packa_timer stoploopsound( 0.05 );
	packa_timer playsound( "zmb_perks_packa_deny" );
	maps/mp/zombies/_zm_weapons::unacquire_weapon_toggle( weapon );
	if ( isDefined( player ) )
	{
		player maps/mp/zombies/_zm_stats::increment_client_stat( "pap_weapon_not_grabbed" );
		player maps/mp/zombies/_zm_stats::increment_player_stat( "pap_weapon_not_grabbed" );
	}
}

wait_for_disconnect( player )
{
	self endon( "pap_taken" );
	self endon( "pap_timeout" );
	name = player.name;
	while ( isDefined( player ) )
	{
		wait 0.1;
	}
	self notify( "pap_player_disconnected" );
}

destroy_weapon_on_disconnect( player )
{
	self endon( "pap_timeout" );
	self endon( "pap_taken" );
	level endon( "Pack_A_Punch_off" );
	player waittill( "disconnect" );
	if ( isDefined( self.worldgun ) )
	{
		if ( isDefined( self.worldgun.worldgundw ) )
		{
			self.worldgun.worldgundw delete();
		}
		self.worldgun delete();
	}
}

destroy_weapon_in_blackout( player )
{
	self endon( "pap_timeout" );
	self endon( "pap_taken" );
	self endon( "pap_player_disconnected" );
	level waittill( "Pack_A_Punch_off" );
	if ( isDefined( self.worldgun ) )
	{
		self.worldgun rotateto( self.worldgun.angles + ( randomint( 90 ) - 45, 0, randomint( 360 ) - 180 ), 1.5, 0, 0 );
		player playlocalsound( level.zmb_laugh_alias );
		wait 1.5;
		if ( isDefined( self.worldgun.worldgundw ) )
		{
			self.worldgun.worldgundw delete();
		}
		self.worldgun delete();
	}
}

do_knuckle_crack()
{
	self endon( "disconnect" );
	gun = self upgrade_knuckle_crack_begin();
	self waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );
	self upgrade_knuckle_crack_end( gun );
}

upgrade_knuckle_crack_begin()
{
	self increment_is_drinking();
	self disable_player_move_states( 1 );
	primaries = self getweaponslistprimaries();
	gun = self getcurrentweapon();
	weapon = level.machine_assets[ "packapunch" ].weapon;
	if ( gun != "none" && !is_placeable_mine( gun ) && !is_equipment( gun ) )
	{
		self notify( "zmb_lost_knife" );
		self takeweapon( gun );
	}
	else
	{
		return;
	}
	self giveweapon( weapon );
	self switchtoweapon( weapon );
	return gun;
}

upgrade_knuckle_crack_end( gun )
{
	self enable_player_move_states();
	weapon = level.machine_assets[ "packapunch" ].weapon;
	if ( self maps/mp/zombies/_zm_laststand::player_is_in_laststand() || is_true( self.intermission ) )
	{
		self takeweapon( weapon );
		return;
	}
	self decrement_is_drinking();
	self takeweapon( weapon );
	primaries = self getweaponslistprimaries();
	if ( self.is_drinking > 0 )
	{
		return;
	}
	else if ( isDefined( primaries ) && primaries.size > 0 )
	{
		self switchtoweapon( primaries[ 0 ] );
	}
	else if ( self hasweapon( level.laststandpistol ) )
	{
		self switchtoweapon( level.laststandpistol );
	}
	else
	{
		self maps/mp/zombies/_zm_weapons::give_fallback_weapon();
	}
}

turn_packapunch_on()
{
	vending_weapon_upgrade_trigger = getentarray( "specialty_weapupgrade", "script_noteworthy" );
	level.pap_triggers = vending_weapon_upgrade_trigger;
	for ( i = 0; i < vending_weapon_upgrade_trigger.size; i++ )
	{
		perk = getent( vending_weapon_upgrade_trigger[ i ].target, "targetname" );
		if ( isDefined( perk ) )
		{
			perk setmodel( level.machine_assets[ "packapunch" ].off_model );
		}
	}
	for ( ;; )
	{
		level waittill( "Pack_A_Punch_on" );
		for ( i = 0; i < vending_weapon_upgrade_trigger.size; i++ )
		{
			perk = getent( vending_weapon_upgrade_trigger[ i ].target, "targetname" );
			if ( isDefined( perk ) )
			{
				perk thread activate_packapunch();
			}
		}
		level waittill( "Pack_A_Punch_off" );
		for ( i = 0; i < vending_weapon_upgrade_trigger.size; i++ )
		{
			perk = getent( vending_weapon_upgrade_trigger[ i ].target, "targetname" );
			if ( isDefined( perk ) )
			{
				perk thread deactivate_packapunch();
			}
		}
	}
}

activate_packapunch()
{
	self setmodel( level.machine_assets[ "packapunch" ].on_model );
	self playsound( "zmb_perks_power_on" );
	self vibrate( vectorScale( ( 0, -1, 0 ), 100 ), 0.3, 0.4, 3 );
	timer = 0;
	duration = 0.05;
}

deactivate_packapunch()
{
	self setmodel( level.machine_assets[ "packapunch" ].off_model );
}

pap_weapon_move_in( trigger, origin_offset, angles_offset )
{
	level endon( "Pack_A_Punch_off" );
	trigger endon( "pap_player_disconnected" );
	trigger.worldgun rotateto( self.angles + angles_offset + vectorScale( ( 0, 1, 0 ), 90 ), 0.35, 0, 0 );
	offsetdw = vectorScale( ( 1, 1, 1 ), 3 );
	if ( isDefined( trigger.worldgun.worldgundw ) )
	{
		trigger.worldgun.worldgundw rotateto( self.angles + angles_offset + vectorScale( ( 0, 1, 0 ), 90 ), 0.35, 0, 0 );
	}
	wait 0.5;
	trigger.worldgun moveto( self.origin + origin_offset, 0.5, 0, 0 );
	if ( isDefined( trigger.worldgun.worldgundw ) )
	{
		trigger.worldgun.worldgundw moveto( self.origin + origin_offset + offsetdw, 0.5, 0, 0 );
	}
}

pap_weapon_move_out( trigger, origin_offset, interact_offset )
{
	level endon( "Pack_A_Punch_off" );
	trigger endon( "pap_player_disconnected" );
	offsetdw = vectorScale( ( 1, 1, 1 ), 3 );
	if ( !isDefined( trigger.worldgun ) )
	{
		return;
	}
	trigger.worldgun moveto( self.origin + interact_offset, 0.5, 0, 0 );
	if ( isDefined( trigger.worldgun.worldgundw ) )
	{
		trigger.worldgun.worldgundw moveto( self.origin + interact_offset + offsetdw, 0.5, 0, 0 );
	}
	wait 0.5;
	if ( !isDefined( trigger.worldgun ) )
	{
		return;
	}
	trigger.worldgun moveto( self.origin + origin_offset, level.packapunch_timeout, 0, 0 );
	if ( isDefined( trigger.worldgun.worldgundw ) )
	{
		trigger.worldgun.worldgundw moveto( self.origin + origin_offset + offsetdw, level.packapunch_timeout, 0, 0 );
	}
}

fx_ent_failsafe()
{
	wait 25;
	self delete();
}

	if ( !isDefined( level.packapunch_timeout ) )
	{
		level.packapunch_timeout = 15;
	}