#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	divetonuke_init_vars();
	perk_struct = spawnStruct();
	perk_struct.cost = 2000;
	perk_struct.hint_string = &"ZOMBIE_PERK_DIVETONUKE";
	perk_struct.perk_bottle = "zombie_perk_bottle_nuke";
	perk_struct.perk_shader = "specialty_divetonuke_zombies";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_flakjacket" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_flakjacket" ];
	}
	else 
	{
		perk_struct.precache_func = ::divetonuke_precache;
	}
	perk_struct.clientfield_register = ::divetonuke_register_clientfield;
	perk_struct.clientfield_set = ::divetonuke_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_flakjacket" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_flakjacket" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::divetonuke_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::divetonuke_perk_give;
	perk_struct.player_thread_take = ::divetonuke_perk_take;
	perk_struct.alias = "divetonuke";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_flakjacket", perk_struct );
}

divetonuke_init_vars()
{
	level.zombiemode_divetonuke_perk_func = ::divetonuke_explode;
	maps/mp/_visionset_mgr::vsmgr_register_info( "visionset", "zm_perk_divetonuke", 9000, 400, 5, 1 );
	set_zombie_var( "zombie_perk_divetonuke_radius", 300 );
	set_zombie_var( "zombie_perk_divetonuke_min_damage", 1000 );
	set_zombie_var( "zombie_perk_divetonuke_max_damage", 5000 );
}

divetonuke_precache()
{
	precacheitem( "zombie_perk_bottle_nuke" );
	precacheshader( "specialty_divetonuke_zombies" );
	precachemodel( "zombie_vending_nuke" );
	precachemodel( "zombie_vending_nuke_on" );
	precachestring( &"ZOMBIE_PERK_DIVETONUKE" );
	level._effect[ "divetonuke_groundhit" ] = loadfx( "maps/zombie/fx_zmb_phdflopper_exp" );
	level._effect[ "divetonuke_light" ] = loadfx( "misc/fx_zombie_cola_dtap_on" );
	level.machine_assets[ "divetonuke" ] = spawnstruct();
	level.machine_assets[ "divetonuke" ].off_model = "zombie_vending_nuke";
	level.machine_assets[ "divetonuke" ].on_model = "zombie_vending_nuke_on";
}

divetonuke_register_clientfield()
{
	registerclientfield( "toplayer", "perk_dive_to_nuke", 9000, 1, "int" );
}

divetonuke_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_dive_to_nuke", state );
}

divetonuke_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
	use_trigger.script_sound = "mus_perks_phd_jingle";
	use_trigger.script_string = "divetonuke_perk";
	use_trigger.script_label = "mus_perks_phd_sting";
	use_trigger.target = "vending_divetonuke";
	perk_machine.script_string = "divetonuke_perk";
	perk_machine.targetname = "vending_divetonuke";
	if ( isDefined( bump_trigger ) )
	{
		bump_trigger.script_string = "divetonuke_perk";
	}
}

divetonuke_explode( attacker, origin )
{
	radius = level.zombie_vars[ "zombie_perk_divetonuke_radius" ];
	min_damage = level.zombie_vars[ "zombie_perk_divetonuke_min_damage" ];
	max_damage = level.zombie_vars[ "zombie_perk_divetonuke_max_damage" ];
	radiusdamage( origin, radius, max_damage, min_damage, attacker, "MOD_GRENADE_SPLASH" );
	playfx( level._effect[ "divetonuke_groundhit" ], origin );
	attacker playsound( "zmb_phdflop_explo" );
	maps/mp/_visionset_mgr::vsmgr_activate( "visionset", "zm_perk_divetonuke", attacker );
	wait 1;
	maps/mp/_visionset_mgr::vsmgr_deactivate( "visionset", "zm_perk_divetonuke", attacker );
}
