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
	perk_struct.hint_string = &"ZOMBIE_PERK_DEADSHOT";
	perk_struct.perk_bottle = "zombie_perk_bottle_deadshot";
	perk_struct.perk_shader = "specialty_ads_zombies";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_deadshot" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_deadshot" ];
	}
	else 
	{
		perk_struct.precache_func = ::deadshot_precache;
	}
	perk_struct.clientfield_register = ::deadshot_register_clientfield;
	perk_struct.clientfield_set = ::deadshot_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_deadshot" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_deadshot" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::deadshot_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::deadshot_perk_give;
	perk_struct.player_thread_take = ::deadshot_perk_take;
	perk_struct.alias = "deadshot";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_deadshot", perk_struct );
}

deadshot_register_clientfield()
{
	registerclientfield( "toplayer", "perk_dead_shot", 1, 2, "int" );
}

deadshot_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_dead_shot", state );
}

deadshot_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
    use_trigger.script_sound = "mus_perks_deadshot_jingle";
    use_trigger.script_string = "deadshot_perk";
    use_trigger.script_label = "mus_perks_deadshot_sting";
    use_trigger.target = "vending_deadshot";
    perk_machine.script_string = "deadshot_vending";
    perk_machine.targetname = "vending_deadshot";
    if ( isDefined( bump_trigger ) )
    {
        bump_trigger.script_string = "deadshot_vending";
    }
}

deadshot_precache()
{
    precacheitem( "zombie_perk_bottle_deadshot" );
    precacheshader( "specialty_ads_zombies" );
    precachemodel( "zombie_vending_ads" );
    precachemodel( "zombie_vending_ads_on" );
    precachestring( &"ZOMBIE_PERK_DEADSHOT" );
    level._effect[ "deadshot_light" ] = loadfx( "misc/fx_zombie_cola_dtap_on" );
    level.machine_assets[ "deadshot" ] = spawnstruct();
    level.machine_assets[ "deadshot" ].off_model = "zombie_vending_ads";
    level.machine_assets[ "deadshot" ].on_model = "zombie_vending_ads_on";
}
