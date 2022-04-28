#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	perk_struct = spawnStruct();
	perk_struct.cost = 3000;
	perk_struct.hint_string = &"ZOMBIE_PERK_FASTRELOAD";
	perk_struct.perk_bottle = "zombie_perk_bottle_sleight";
	perk_struct.perk_shader = "specialty_fastreload_zombies";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_fastreload" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_fastreload" ];
	}
	else 
	{
		perk_struct.precache_func = ::fastreload_precache;
	}
	perk_struct.clientfield_register = ::fastreload_register_clientfield;
	perk_struct.clientfield_set = ::fastreload_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_fastreload" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_fastreload" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::fastreload_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::fastreload_perk_give;
	perk_struct.player_thread_take = ::fastreload_perk_lost;
	perk_struct.alias = "sleight";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_fastreload", perk_struct );
}

fastreload_register_clientfield()
{
	registerclientfield( "toplayer", "perk_sleight_of_hand", 1, 2, "int" );
}

fastreload_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_sleight_of_hand", state );
}

fastreload_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
    use_trigger.script_sound = "mus_perks_speed_jingle";
    use_trigger.script_string = "speedcola_perk";
    use_trigger.script_label = "mus_perks_speed_sting";
    use_trigger.target = "vending_sleight";
    perk_machine.script_string = "speedcola_perk";
    perk_machine.targetname = "vending_sleight";
    if ( isDefined( bump_trigger ) )
    {
        bump_trigger.script_string = "speedcola_perk";
    }
}

fastreload_precache()
{
    precacheitem( "zombie_perk_bottle_sleight" );
    precacheshader( "specialty_fastreload_zombies" );
    precachemodel( "zombie_vending_sleight" );
    precachemodel( "zombie_vending_sleight_on" );
    precachestring( &"ZOMBIE_PERK_FASTRELOAD" );
    level._effect[ "sleight_light" ] = loadfx( "misc/fx_zombie_cola_on" );
    level.machine_assets[ "specialty_fastreload" ] = spawnstruct();
    level.machine_assets[ "specialty_fastreload" ].off_model = "zombie_vending_sleight";
    level.machine_assets[ "specialty_fastreload" ].on_model = "zombie_vending_sleight_on";
}
