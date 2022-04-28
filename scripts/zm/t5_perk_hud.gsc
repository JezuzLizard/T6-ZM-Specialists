#include maps\mp\_utility; 
#include common_scripts\utility; 
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_perks;

main()
{
	replaceFunc( maps\mp\zombies\_zm_perks::give_perk, ::give_perk_override );
	replaceFunc( maps\mp\zombies\_zm_perks::perk_think, ::perk_think_override );
}

give_perk_override( perk, bought )
{
    self setperk( perk );
    self.num_perks++;
    if ( isdefined( bought ) && bought )
    {
        self maps\mp\zombies\_zm_audio::playerexert( "burp" );

        if ( isdefined( level.remove_perk_vo_delay ) && level.remove_perk_vo_delay )
            self maps\mp\zombies\_zm_audio::perk_vox( perk );
        else
            self delay_thread( 1.5, maps\mp\zombies\_zm_audio::perk_vox, perk );

        self setblur( 4, 0.1 );
        wait 0.1;
        self setblur( 0, 0.1 );
        self notify( "perk_bought", perk );
    }
    self perk_set_max_health_if_jugg( perk, 1, 0 );
    if ( perk == "specialty_scavenger" )
        self.hasperkspecialtytombstone = 1;
    players = getPlayers();
    if ( use_solo_revive() && perk == "specialty_quickrevive" )
    {
        self.lives = 1;
        if ( !isdefined( level.solo_lives_given ) )
            level.solo_lives_given = 0;
        if ( isdefined( level.solo_game_free_player_quickrevive ) )
            level.solo_game_free_player_quickrevive = undefined;
        else
            level.solo_lives_given++;
        if ( level.solo_lives_given >= 3 )
            flag_set( "solo_revive" );
        self thread solo_revive_buy_trigger_move( perk );
    }
    if ( perk == "specialty_finalstand" )
    {
        self.lives = 1;
        self.hasperkspecialtychugabud = 1;
        self notify( "perk_chugabud_activated" );
    }
    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_give ) )
        self thread [[ level._custom_perks[perk].player_thread_give ]]();
    self perk_hud_create( perk );
    maps\mp\_demo::bookmark( "zm_player_perk", gettime(), self );
    self maps\mp\zombies\_zm_stats::increment_client_stat( "perks_drank" );
    self maps\mp\zombies\_zm_stats::increment_client_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( "perks_drank" );
    if ( !isdefined( self.perk_history ) )
        self.perk_history = [];
    self.perk_history = add_to_array( self.perk_history, perk, 0 );
    if ( !isdefined( self.perks_active ) )
        self.perks_active = [];
    self.perks_active[self.perks_active.size] = perk;
    self notify( "perk_acquired" );
    self thread perk_think( perk );
}

perk_think_override( perk )
{
    perk_str = perk + "_stop";
    result = self waittill_any_return( "fake_death", "death", "player_downed", perk_str );
    do_retain = 1;
    if ( use_solo_revive() && perk == "specialty_quickrevive" )
        do_retain = 0;
    if ( do_retain )
    {
        if ( isdefined( self._retain_perks ) && self._retain_perks )
            return;
        else if ( isdefined( self._retain_perks_array ) && isdefined( self._retain_perks_array[perk] ) && self._retain_perks_array[perk] )
            return;
    }
    self unsetperk( perk );
    self.num_perks--;
    switch ( perk )
    {
        case "specialty_armorvest":
            self setmaxhealth( 100 );
            break;
        case "specialty_additionalprimaryweapon":
            if ( result == perk_str )
                self maps\mp\zombies\_zm::take_additionalprimaryweapon();
            break;
    }
    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_take ) )
        self thread [[ level._custom_perks[perk].player_thread_take ]]();
    self perk_hud_destroy( perk );
    self.perk_purchased = undefined;
    if ( isdefined( level.perk_lost_func ) )
        self [[ level.perk_lost_func ]]( perk );
    if ( isdefined( self.perks_active ) && isinarray( self.perks_active, perk ) )
        arrayremovevalue( self.perks_active, perk, 0 );
    self notify( "perk_lost" );
}

perk_hud_create( perk )
{
	if ( !IsDefined( self.perk_hud ) )
	{
		self.perk_hud = [];
	}
	shader = "";
	switch( perk )
	{
	case "specialty_armorvest":
		shader = "specialty_juggernaut_zombies";
		break;
	case "specialty_quickrevive":
		shader = "specialty_quickrevive_zombies";
		break;
	case "specialty_fastreload":
		shader = "specialty_fastreload_zombies";
		break;
	case "specialty_rof":
		shader = "specialty_doubletap_zombies";
		break;
	case "specialty_longersprint":
		shader = "specialty_marathon_zombies";
		break;
	case "specialty_flakjacket":
		shader = "specialty_divetonuke_zombies";
		break;
	case "specialty_deadshot":
		shader = "specialty_ads_zombies"; 
		break;
	case "specialty_additionalprimaryweapon":
		shader = "specialty_extraprimaryweapon_zombies";
		break;
	case "specialty_scavenger":
		shader = "specialty_tombstone_zombies";
		break;
	case "specialty_finalstand":
		shader = "specialty_chugabud_zombies";
		break;
	case "specialty_grenadepulldeath":
		shader = "specialty_electric_cherry_zombie";
		break;
	case "specialty_nomotionsensor":
		shader = "specialty_vulture_zombies";
		break;
	default:
		shader = "";
		break;
	}
	hud = create_simple_hud( self );
	hud.foreground = true; 
	hud.sort = 1; 
	hud.hidewheninmenu = false; 
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_bottom";
	hud.x = self.perk_hud.size * 30; 
	hud.y = hud.y - 70; 
	hud.alpha = 1;
	hud SetShader( shader, 24, 24 );
	self.perk_hud[ perk ] = hud;
}


perk_hud_destroy( perk )
{
	self.perk_hud[ perk ] destroy_hud();
	self.perk_hud[ perk ] = undefined;
}