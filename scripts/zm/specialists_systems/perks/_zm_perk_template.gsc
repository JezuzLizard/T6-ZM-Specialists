#include maps/mp/_visionset_mgr;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

register_perk()
{
	perk_struct = spawnStruct();
	perk_struct.cost = 4000;
	perk_struct.hint_string = "Perk Display Name";
	perk_struct.perk_bottle = "zombie_perk_bottle_additionalprimaryweapon";
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
	maps/mp/zombies/_zm_perks::register_perk_basic_info( "custom_perk", perk_struct );
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
    //the logic goes here bro.
}

additionalprimaryweapon_perk_take()
{
	//take that shit away here.
}