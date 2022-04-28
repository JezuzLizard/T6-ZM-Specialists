#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	armorvest_init_vars();
	perk_struct = spawnStruct();
	perk_struct.cost = 2500;
	perk_struct.hint_string = &"ZOMBIE_PERK_JUGGERNAUT";
	perk_struct.perk_bottle = "zombie_perk_bottle_jugg";
	perk_struct.perk_shader = "specialty_juggernaut_zombies";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_armorvest" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_armorvest" ];
	}
	else 
	{
		perk_struct.precache_func = ::armorvest_precache;
	}
	perk_struct.clientfield_register = ::armorvest_register_clientfield;
	perk_struct.clientfield_set = ::armorvest_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_armorvest" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_armorvest" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::armorvest_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::armorvest_perk_take;
	perk_struct.player_thread_take = ::armorvest_perk_give;
	perk_struct.alias = "jugg";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_armorvest", perk_struct );
}

armorvest_init_vars()
{
	set_zombie_var( "zombie_perk_juggernaut_health", 160 );
}

armorvest_register_clientfield()
{
	registerclientfield( "toplayer", "perk_juggernaut", 1, 2, "int" );
}

armorvest_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_juggernaut", state );
}

armorvest_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
	use_trigger.script_sound = "mus_perks_jugganog_jingle";
	use_trigger.script_string = "jugg_perk";
	use_trigger.script_label = "mus_perks_jugganog_sting";
	use_trigger.longjinglewait = 1;
	use_trigger.target = "vending_jugg";
	perk_machine.script_string = "jugg_perk";
	perk_machine.targetname = "vending_jugg";
	if ( isDefined( bump_trigger ) )
	{
		bump_trigger.script_string = "jugg_perk";
	}
}

armorvest_precache()
{
	precacheitem( "zombie_perk_bottle_jugg" );
	precacheshader( "specialty_juggernaut_zombies" );
	precachemodel( "zombie_vending_jugg" );
	precachemodel( "zombie_vending_jugg_on" );
	precachestring( &"ZOMBIE_PERK_JUGGERNAUT" );
	level._effect[ "jugger_light" ] = loadfx( "misc/fx_zombie_cola_jugg_on" );
	level.machine_assets[ "specialty_armorvest" ] = spawnstruct();
	level.machine_assets[ "specialty_armorvest" ].off_model = "zombie_vending_jugg";
	level.machine_assets[ "specialty_armorvest" ].on_model = "zombie_vending_jugg_on";
}

armorvest_perk_give()
{
	if ( player hasPerk( "specialty_armorvest" ) )
	{
		self perk_set_max_health_if_jugg( "specialty_armorvest", 0, 0 );
	}
	else 
	{
		self perk_set_max_health_if_jugg( "specialty_armorvest", 1, 0 );
	}
}

armorvest_perk_take()
{
	self setMaxHealth( self.premaxhealth );
	if ( self.health > self.maxhealth )
	{
		self.health = self.maxhealth;
	}
}