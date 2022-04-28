#include maps/mp/zombies/_zm_ai_basic;
#include maps/mp/animscripts/shared;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	electric_cherry_init_vars();
	perk_struct = spawnStruct();
	perk_struct.cost = 2000;
	perk_struct.hint_string = &"ZM_PRISON_PERK_CHERRY";
	perk_struct.perk_bottle = "zombie_perk_bottle_cherry";
	perk_struct.perk_shader = "specialty_electric_cherry_zombie";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_grenadepulldeath" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_grenadepulldeath" ];
	}
	else 
	{
		perk_struct.precache_func = ::electric_cherry_precache;
	}
	perk_struct.clientfield_register = ::electric_cherry_register_clientfield;
	perk_struct.clientfield_set = ::electric_cherry_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_grenadepulldeath" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_grenadepulldeath" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::electric_cherry_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::electric_cherry_reload_attack;
	perk_struct.player_thread_take = ::electric_cherry_perk_lost;
	perk_struct.alias = "electric_cherry";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_grenadepulldeath", perk_struct );
}

electric_cherry_init_vars()
{
	level.custom_laststand_func = ::electric_cherry_laststand;
	set_zombie_var( "tesla_head_gib_chance", 50 );
	registerclientfield( "allplayers", "electric_cherry_reload_fx", 9000, 2, "int" );
}

electic_cherry_precache()
{
	precacheitem( "zombie_perk_bottle_cherry" );
	precacheshader( "specialty_fastreload_zombies" );
	precachemodel( "p6_zm_vending_electric_cherry_off" );
	precachemodel( "p6_zm_vending_electric_cherry_on" );
	precachestring( &"ZM_PRISON_PERK_CHERRY" );
	level._effect[ "electric_cherry_light" ] = loadfx( "misc/fx_zombie_cola_on" );
	level._effect[ "electric_cherry_explode" ] = loadfx( "maps/zombie_alcatraz/fx_alcatraz_electric_cherry_down" );
	level._effect[ "electric_cherry_reload_small" ] = loadfx( "maps/zombie_alcatraz/fx_alcatraz_electric_cherry_sm" );
	level._effect[ "electric_cherry_reload_medium" ] = loadfx( "maps/zombie_alcatraz/fx_alcatraz_electric_cherry_player" );
	level._effect[ "electric_cherry_reload_large" ] = loadfx( "maps/zombie_alcatraz/fx_alcatraz_electric_cherry_lg" );
	level._effect[ "tesla_shock" ] = loadfx( "maps/zombie/fx_zombie_tesla_shock" );
	level._effect[ "tesla_shock_secondary" ] = loadfx( "maps/zombie/fx_zombie_tesla_shock_secondary" );
	level.machine_assets[ "specialty_grenadepulldeath" ] = spawnstruct();
	level.machine_assets[ "specialty_grenadepulldeath" ].on_model = "p6_zm_vending_electric_cherry_on";
	level.machine_assets[ "specialty_grenadepulldeath" ].off_model = "p6_zm_vending_electric_cherry_off";
}

electric_cherry_register_clientfield()
{
	registerclientfield( "toplayer", "perk_electric_cherry", 9000, 1, "int" );
}

electric_cherry_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_electric_cherry", state );
}

electric_cherry_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
	use_trigger.script_sound = "mus_perks_cherry_jingle";
	use_trigger.script_string = "electric_cherry_perk";
	use_trigger.script_label = "mus_perks_cherry_sting";
	use_trigger.target = "vending_electric_cherry";
	perk_machine.script_string = "electric_cherry_perk";
	perk_machine.targetname = "vending_electric_cherry";
	if ( isDefined( bump_trigger ) )
	{
		bump_trigger.script_string = "electric_cherry_perk";
	}
}

electric_cherry_laststand()
{
	visionsetlaststand( "zombie_last_stand", 1 );
	if ( isDefined( self ) )
	{
		playfx( level._effect[ "electric_cherry_explode" ], self.origin );
		self playsound( "zmb_cherry_explode" );
		self notify( "electric_cherry_start" );
		wait 0.05;
		a_zombies = getaispeciesarray( "axis", "all" );
		a_zombies = get_array_of_closest( self.origin, a_zombies, undefined, undefined, 500 );
		for ( i = 0; i < a_zombies.size; i++) 
		{
			if ( isalive( self ) )
			{
				if ( a_zombies[ i ].health <= 1000 )
				{
					a_zombies[ i ] thread electric_cherry_death_fx();
					if ( isdefined( self.cherry_kills ) )
					{
						self.cherry_kills++;
					}
					self maps/mp/zombies/_zm_score::add_to_player_score( 40 );
				}
				else
				{
					a_zombies[ i ] thread electric_cherry_stun();
					a_zombies[ i ] thread electric_cherry_shock_fx();
				}
				wait 0.1 ;
				a_zombies[ i ] dodamage( 1000, self.origin, self, self, "none" );
			}
		}
		self notify( "electric_cherry_end" );
	}
}

electric_cherry_death_fx()
{
	self endon( "death" );
	tag = "J_SpineUpper";
	fx = "tesla_shock";
	if ( self.isdog )
	{
		tag = "J_Spine1";
	}
	self playsound( "zmb_elec_jib_zombie" );
	network_safe_play_fx_on_tag( "tesla_death_fx", 2, level._effect[ fx ], self, tag );
	if ( isDefined( self.tesla_head_gib_func ) && !self.head_gibbed )
	{
		[[ self.tesla_head_gib_func ]]();
	}
}

electric_cherry_shock_fx()
{
	self endon( "death" );
	tag = "J_SpineUpper";
	fx = "tesla_shock_secondary";
	if ( self.isdog )
	{
		tag = "J_Spine1";
	}
	self playsound( "zmb_elec_jib_zombie" );
	network_safe_play_fx_on_tag( "tesla_shock_fx", 2, level._effect[ fx ], self, tag );
}

electric_cherry_stun()
{
	self endon( "death" );
	self notify( "stun_zombie" );
	self endon( "stun_zombie" );
	if ( self.health <= 0 )
	{
		return;
	}
	if ( self.ai_state != "find_flesh" )
	{
		return;
	}
	self.forcemovementscriptstate = 1;
	self.ignoreall = 1;
	for ( i = 0; i < 2; i++ )
	{
		self animscripted( self.origin, self.angles, "zm_afterlife_stun" );
		self maps/mp/animscripts/shared::donotetracks( "stunned" );
	}
	self.forcemovementscriptstate = 0;
	self.ignoreall = 0;
	self setgoalpos( self.origin );
	self thread maps/mp/zombies/_zm_ai_basic::find_flesh();
}

electric_cherry_reload_attack()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "stop_electric_cherry_reload_attack" );
	self.wait_on_reload = [];
	self.consecutive_electric_cherry_attacks = 0;
	while ( 1 )
	{
		self waittill( "reload_start" );
		str_current_weapon = self getcurrentweapon();
		if ( isinarray( self.wait_on_reload, str_current_weapon ) )
		{
			continue;
		}
		self.wait_on_reload[ self.wait_on_reload.size ] = str_current_weapon;
		self.consecutive_electric_cherry_attacks++;
		n_clip_current = self getweaponammoclip( str_current_weapon );
		n_clip_max = weaponclipsize( str_current_weapon );
		n_fraction = n_clip_current / n_clip_max;
		perk_radius = linear_map( n_fraction, 1, 0, 32, 128 );
		perk_dmg = linear_map( n_fraction, 1, 0, 1, 1045 );
		self thread check_for_reload_complete( str_current_weapon );
		if ( isDefined( self ) )
		{
			switch( self.consecutive_electric_cherry_attacks )
			{
				case 0:
				case 1:
					n_zombie_limit = undefined;
					break;
				case 2:
					n_zombie_limit = 8;
					break;
				case 3:
					n_zombie_limit = 4;
					break;
				case 4:
					n_zombie_limit = 2;
					break;
				default:
					n_zombie_limit = 0;
			}
			self thread electric_cherry_cooldown_timer( str_current_weapon );
			if ( isDefined( n_zombie_limit ) && n_zombie_limit == 0 )
			{
				continue;
			}
			self thread electric_cherry_reload_fx( n_fraction );
			self notify( "electric_cherry_start" );
			self playsound( "zmb_cherry_explode" );
			a_zombies = getaispeciesarray( "axis", "all" );
			a_zombies = get_array_of_closest( self.origin, a_zombies, undefined, undefined, perk_radius );
			n_zombies_hit = 0;
			for ( i = 0; i < a_zombies.size; i++ )
			{
				if ( isalive( self ) && isalive( a_zombies[ i ] ) )
				{
					if ( isDefined( n_zombie_limit ) )
					{
						if ( n_zombies_hit < n_zombie_limit )
						{
							n_zombies_hit++;	
						}
						else 
						{
							break;
						}
					}
					if ( a_zombies[ i ].health <= perk_dmg )
					{
						a_zombies[ i ] thread electric_cherry_death_fx();
						if ( isDefined( self.cherry_kills ) )
						{
							self.cherry_kills++;
						}
						self maps/mp/zombies/_zm_score::add_to_player_score( 40 );
					}
					else if ( !is_true( a_zombies[ i ].immune_to_cherry_stun ) )
					{
						a_zombies[ i ] thread electric_cherry_stun();
					}
					a_zombies[ i ] thread electric_cherry_shock_fx();
					wait 0.1;
					if ( isalive( a_zombies[ i ] ) )
					{
						a_zombies[ i ] dodamage( perk_dmg, self.origin, self, self, "none" );
					}
				}
			}
			self notify( "electric_cherry_end" );
		}
	}
}

electric_cherry_cooldown_timer( str_current_weapon )
{
	self notify( "electric_cherry_cooldown_started" );
	self endon( "electric_cherry_cooldown_started" );
	self endon( "death" );
	self endon( "disconnect" );
	n_reload_time = weaponreloadtime( str_current_weapon );
	if ( self hasperk( "specialty_fastreload" ) )
	{
		n_reload_time *= getDvarFloat( "perk_weapReloadMultiplier" );
	}
	n_cooldown_time = n_reload_time + 3;
	wait n_cooldown_time;
	self.consecutive_electric_cherry_attacks = 0;
}

check_for_reload_complete( weapon )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "player_lost_weapon_" + weapon );
	self thread weapon_replaced_monitor( weapon );
	while ( 1 )
	{
		self waittill( "reload" );
		str_current_weapon = self getcurrentweapon();
		if ( str_current_weapon == weapon )
		{
			arrayremovevalue( self.wait_on_reload, weapon );
			self notify( "weapon_reload_complete_" + weapon );
			break;
		}
	}
}

weapon_replaced_monitor( weapon )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "weapon_reload_complete_" + weapon );
	while ( 1 )
	{
		self waittill( "weapon_change" );
		primaryweapons = self getweaponslistprimaries();
		if ( !isinarray( primaryweapons, weapon ) )
		{
			self notify( "player_lost_weapon_" + weapon );
			arrayremovevalue( self.wait_on_reload, weapon );
			break;
		}
	}
}

electric_cherry_reload_fx( n_fraction )
{
	if ( n_fraction >= 0.67 )
	{
		self setclientfield( "electric_cherry_reload_fx", 1 );
	}
	else if ( n_fraction >= 0.33 && n_fraction < 0.67 )
	{
		self setclientfield( "electric_cherry_reload_fx", 2 );
	}
	else
	{
		self setclientfield( "electric_cherry_reload_fx", 3 );
	}
	wait 1;
	self setclientfield( "electric_cherry_reload_fx", 0 );
}

electric_cherry_perk_lost()
{
	self notify( "stop_electric_cherry_reload_attack" );
}




