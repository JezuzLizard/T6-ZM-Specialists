#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	perk_struct = spawnStruct();
	perk_struct.cost = 2000;
	perk_struct.hint_string = &"ZOMBIE_PERK_DOUBLETAP";
	perk_struct.perk_bottle = "zombie_perk_bottle_doubletap";
	perk_struct.perk_shader = "specialty_doubletap_zombies";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_rof" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_rof" ];
	}
	else 
	{
		perk_struct.precache_func = ::rof_precache;
	}
	perk_struct.clientfield_register = ::rof_register_clientfield;
	perk_struct.clientfield_set = ::rof_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_rof" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_rof" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::rof_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::rof_perk_give;
	perk_struct.player_thread_take = ::rof_perk_lost;
	perk_struct.alias = "doubletap";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_rof", perk_struct );
}

rof_register_clientfield()
{
	registerclientfield( "toplayer", "perk_double_tap", 1, 2, "int" );
}

rof_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_double_tap", state );
}

rof_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
    use_trigger.script_sound = "mus_perks_doubletap_jingle";
    use_trigger.script_string = "tap_perk";
    use_trigger.script_label = "mus_perks_doubletap_sting";
    use_trigger.target = "vending_doubletap";
    perk_machine.script_string = "tap_perk";
    perk_machine.targetname = "vending_doubletap";
    if ( isDefined( bump_trigger ) )
    {
        bump_trigger.script_string = "tap_perk";
    }
}

rof_precache()
{
    precacheitem( "zombie_perk_bottle_doubletap" );
    precacheshader( "specialty_doubletap_zombies" );
    precachemodel( "zombie_vending_doubletap2" );
    precachemodel( "zombie_vending_doubletap2_on" );
    precachestring( &"ZOMBIE_PERK_DOUBLETAP" );
    level._effect[ "doubletap_light" ] = loadfx( "misc/fx_zombie_cola_dtap_on" );
    level.machine_assets[ "specialty_rof" ] = spawnstruct();
    level.machine_assets[ "specialty_rof" ].off_model = "zombie_vending_doubletap2";
    level.machine_assets[ "specialty_rof" ].on_model = "zombie_vending_doubletap2_on";
}
