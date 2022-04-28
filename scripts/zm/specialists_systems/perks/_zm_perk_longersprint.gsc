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
	perk_struct.hint_string = &"ZOMBIE_PERK_MARATHON";
	perk_struct.perk_bottle = "zombie_perk_bottle_marathon";
	perk_struct.perk_shader = "specialty_marathon_zombies";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_longersprint" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_longersprint" ];
	}
	else 
	{
		perk_struct.precache_func = ::longersprint_precache;
	}
	perk_struct.clientfield_register = ::longersprint_register_clientfield;
	perk_struct.clientfield_set = ::longersprint_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_longersprint" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_longersprint" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::longersprint_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::longersprint_perk_give;
	perk_struct.player_thread_take = ::longersprint_perk_lost;
	perk_struct.alias = "marathon";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_longersprint", perk_struct );
}

longersprint_register_clientfield()
{
	registerclientfield( "toplayer", "perk_marathon", 1, 2, "int" );
}

longersprint_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_marathon", state );
}

longersprint_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
    use_trigger.script_sound = "mus_perks_stamin_jingle";
    use_trigger.script_string = "marathon_perk";
    use_trigger.script_label = "mus_perks_stamin_sting";
    use_trigger.target = "vending_marathon";
    perk_machine.script_string = "marathon_perk";
    perk_machine.targetname = "vending_marathon";
    if ( isDefined( bump_trigger ) )
    {
        bump_trigger.script_string = "marathon_perk";
    }
}

longersprint_precache()
{
    precacheitem( "zombie_perk_bottle_marathon" );
    precacheshader( "specialty_marathon_zombies" );
    precachemodel( "zombie_vending_marathon" );
    precachemodel( "zombie_vending_marathon_on" );
    precachestring( &"ZOMBIE_PERK_MARATHON" );
    level._effect[ "marathon_light" ] = loadfx( "maps/zombie/fx_zmb_cola_staminup_on" );
    level.machine_assets[ "specialty_longersprint" ] = spawnstruct();
    level.machine_assets[ "specialty_longersprint" ].off_model = "zombie_vending_marathon";
    level.machine_assets[ "specialty_longersprint" ].on_model = "zombie_vending_marathon_on";
}
