#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	additionalprimaryweapon_init_vars();
	perk_struct = spawnStruct();
	perk_struct.cost = 4000;
	perk_struct.hint_string = &"ZOMBIE_PERK_ADDITIONALPRIMARYWEAPON";
	perk_struct.perk_bottle = "zombie_perk_bottle_additionalprimaryweapon";
	perk_struct.perk_shader = "specialty_extraprimaryweapon_zombies";
	if ( isDefined( level.perk_power_on_func ) )
	{
		perk_struct.power_on_callback = level.perk_power_on_func;
	}
	if ( isDefined( level.perk_power_off_func ) )
	{
		perk_struct.power_off_callback = level.perk_power_off_func;
	}
	if ( isDefined( level.perk_precache_override_funcs[ "specialty_additionalprimaryweapon" ] ) )
	{
		perk_struct.precache_func = level.perk_precache_override_funcs[ "specialty_additionalprimaryweapon" ];
	}
	else 
	{
		perk_struct.precache_func = ::additionalprimaryweapon_precache;
	}
	perk_struct.clientfield_register = ::additionalprimaryweapon_register_clientfield;
	perk_struct.clientfield_set = ::additionalprimaryweapon_set_clientfield;
	perk_struct.funcs = [];
	if ( isDefined( level.perk_kvps_override_funcs[ "specialty_additionalprimaryweapon" ] ) )
	{
		perk_struct.perk_machine_set_kvps = level.perk_kvps_override_funcs[ "specialty_additionalprimaryweapon" ];
	}
	else 
	{
		perk_struct.perk_machine_set_kvps = ::additionalprimaryweapon_perk_machine_setup;
	}
	perk_struct.player_thread_give = ::additionalprimaryweapon_perk_give;
	perk_struct.player_thread_take = ::additionalprimaryweapon_perk_take;
	perk_struct.alias = "additionalprimaryweapon";
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "specialty_additionalprimaryweapon", perk_struct );
}

additionalprimaryweapon_init_vars()
{
	level.additionalprimaryweapon_limit = 3;
}

additionalprimaryweapon_register_clientfield()
{
	registerclientfield( "toplayer", "perk_additional_primary_weapon", 1, 2, "int" );
}

additionalprimaryweapon_set_clientfield( state )
{
	self setclientfieldtoplayer( "perk_additional_primary_weapon", state );
}

additionalprimaryweapon_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
    use_trigger.script_sound = "mus_perks_mulekick_jingle";
    use_trigger.script_string = "tap_perk";
    use_trigger.script_label = "mus_perks_mulekick_sting";
    use_trigger.target = "vending_additionalprimaryweapon";
    perk_machine.script_string = "tap_perk";
    perk_machine.targetname = "vending_additionalprimaryweapon";
    if ( isDefined( bump_trigger ) )
    {
        bump_trigger.script_string = "tap_perk";
    }
}

additionalprimaryweapon_precache()
{
    precacheitem( "zombie_perk_bottle_additionalprimaryweapon" );
    precacheshader( "specialty_additionalprimaryweapon_zombies" );
    precachemodel( "zombie_vending_three_gun" );
    precachemodel( "zombie_vending_three_gun_on" );
    precachestring( &"ZOMBIE_PERK_ADDITIONALWEAPONPERK" );
    level._effect[ "additionalprimaryweapon_light" ] = loadfx( "misc/fx_zombie_cola_arsenal_on" );
    level.machine_assets[ "specialty_additionalprimaryweapon" ] = spawnstruct();
    level.machine_assets[ "specialty_additionalprimaryweapon" ].off_model = "zombie_vending_three_gun";
    level.machine_assets[ "specialty_additionalprimaryweapon" ].on_model = "zombie_vending_three_gun_on";
}

additionalprimaryweapon_perk_give()
{

}

additionalprimaryweapon_perk_take()
{
	self maps/mp/zombies/_zm::take_additionalprimaryweapon();
}