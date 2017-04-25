/*******************************************************************************
                        # Changelog
    v0.1 - 07/05/2015:
        - Script Criado.
        - Comandos para criar, destruir e alterar actors.
        - Lista de comandos para saber de todos os comandos disponíveis.
        - Possível executar/parar animação em um ou todos actors.
    v0.1 R2 - 07/05/2015:
        - Comando /criaractor corrigido, setando a posição do jogador para o lado, para não ocorrer bugs.
        - Debugs desabilitados.
    v0.1 R3 - 08/05/2015:
        - Comando /criaractor alterado. Agora actors podem ser identificados com nomes.
        - Novo comando: /reviveractor. Ele revive o actor na mesma posição.
        - Labels identificam os actors com seu id e nome.
        - Novo comando: /alteraractornome. Alterar o nome do actor.
        - Os comandos só podem ser utilizados por administradores (RCON).
        - Comando /veractors exibe agora 25 resultados por página.
    v0.1 R4 - 24/05/2015:
        - Comando /exportaractors. Gera um script semi pronto com todos os actors criados para um arquivo desejado.
################################################################################
    v0.2  - 24/04/2017:
        - Possibilidade de usar o plugin streamer (v2.9+).
            Defina USE_STREAMER. Com isto, o LIMITE foi aumentado!
        - Comando /alteraractornome para /nomeactor.
        - Novo comando: /editaractor
            Mover o actor como se fosse objeto
        - Adicionado comandos abreviados




*******************************************************************************/
#include <a_samp>
#include <zcmd>
#include <sscanf2>

#define USE_STREAMER
#if defined USE_STREAMER
    #include <streamer>       // 2.9++
    #if !defined CreateDynamicActor
        #error Plugin Streamer Desatualizado!
    #endif
    #undef MAX_ACTORS
    #define MAX_ACTORS  10000 // Seu Limite
#endif

#define DIALOG_ACTORCMDS 32002
#define DIALOG_VERACTORS 32003

enum cmd_infos
{
    Comando[128],
    Abreviado[128],
    Descricao[128]
};
new cmds_Actor[][cmd_infos] = {
    {"/criaractor [skin id] [nome]",                        "/cac",         "Cria um actor com a skin desejada e com um nome"},
    {"/destruiractor [actor id]",                           "/dac",         "Destroi um actor"},
    {"/destruirtodosactors",                                "/dta",         "Destrói todos os actors do servidor"},
    {"/animaractor [actor id] [animlib] [animname] [loop]", "/ania",        "Anima um actor"},
    {"/pararanimactor [actor id]",                          "/pana",        "Para a animação de um actor"},
    {"/animtodosactors [animlib] [animname] [loop]",        "/anta",        "Anima todos os actors do servidor"},
    {"/pararanimtodosactors",                               "/panta",       "Para a animação de todos os actors"},
    {"/actorpos [actor id] [x] [y] [z] [rotação]",          "/apos",        "Seta a posição de um actor"},
    {"/actormundo [actor id] [mundo virtual]",              "/amun",        "Seta o mundo virtual de um actor"},
    {"/actorvuneravel [actor id]",                          "/acin",        "Deixa um actor vuneravel/invuneravel"},
    {"/actorvida [actor id] [vida]",                        "/acv",         "Seta a vida de um actor"},
    {"/reviveractor [actor id]",                            "/reva",        "Revive um actor"},
    {"/nomeactor [actor id] [novo nome]",                   "/nac",         "Altera o nome de um actor"},
    {"/editaractor [actor id]",                             "/eda",         "Edita a posição de um actor"},
    {"/veractors",                                          "/va",          "Visualiza os actors criados"},
    {"/exportaractors [arquivo.pwn]",                       "/exa",         "Gera um script semi-pronto para uso dos actors criados"},
    {"/comandosactor",                                      "/acmd",        "Visualiza a página de comandos de actors"}
};

enum i_actor
{
    ActorNome[32],
    ActorSkin,
    Text3D:ActorLabel,
    ActorObject         // v0.2
};
new ActorData[MAX_ACTORS][i_actor];

public OnFilterScriptInit()
{
    for(new i; i < MAX_ACTORS; i++) {
        ActorData[i][ActorSkin] = -1;
        ActorData[i][ActorLabel] = Text3D:INVALID_3DTEXT_ID;
        format(ActorData[i][ActorNome], 32, "");
    }
    print("*****************************************");
    print("**** Actor debug - básico [CARREGADO]****");
    #if defined USE_STREAMER
        print("******* Utilizando plugin: streamer ******");
    #endif
    print("*****************************************");
	return 1;
}

public OnFilterScriptExit()
{
    for(new i; i <= GetActorPoolSize(); i++) {
        #if !defined USE_STREAMER
        if(!IsValidActor(i)) continue;
        #else
        if(!IsValidDynamicActor(i)) continue;
        #endif
        if(ActorData[i][ActorSkin] != -1) {
            #if !defined USE_STREAMER
            DestroyActor(i);
            Delete3DTextLabel(ActorData[i][ActorLabel]);
            DestroyObject(ActorData[i][ActorObject]);
            #else
            DestroyDynamicActor(i);
            DestroyDynamic3DTextLabel(ActorData[i][ActorLabel]);
            DestroyDynamicObject(ActorData[i][ActorObject]);
            #endif
            ActorData[i][ActorSkin] = -1;
            format(ActorData[i][ActorNome], 32, "");
        }
    }
    print("*****************************************");
    print("**** Actor debug - básico [DESLIGADO]****");
    print("*****************************************");
	return 1;
}

public OnPlayerSpawn(playerid) {
    if(IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "{FFFF00}* Sistema de Testes de Actors está ligado. Use /acmd para ver os comandos!");
    return 1;
}
/////////// Comandos //////////////
CMD:criaractor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new skin_actor, Nome[32];
    if(sscanf(params, "is[32]", skin_actor, Nome)) return SendClientMessage(playerid, -1, "{FF0000}Use: /criaractor [skin id] [nome]");
    if(skin_actor < 0 || skin_actor > 311) return SendClientMessage(playerid, -1, "{FF0000}O id é inválido!");
    new Float:pP[4], Msg[144], Actorid;
    GetPlayerPos(playerid, pP[0], pP[1], pP[2]);
    GetPlayerFacingAngle(playerid, pP[3]);
    #if !defined USE_STREAMER
        Actorid = CreateActor(skin_actor, pP[0], pP[1], pP[2], pP[3]);
        if(!IsValidActor(Actorid)) return SendClientMessage(playerid, -1, "{FF0000}Ocorreu um erro. Provavelmente o máximo de actors foi atingido!");
        SetActorVirtualWorld(Actorid, GetPlayerVirtualWorld(playerid));
        format(Msg, 144, "%s (%i)", Nome, Actorid);
        ActorData[Actorid][ActorLabel] = Create3DTextLabel(Msg, 0xFFFF00AA, pP[0], pP[1], pP[2] + 1.0, 30.0, GetPlayerVirtualWorld(playerid));
        ActorData[Actorid][ActorObject] = CreateObject(1924, pP[0], pP[1], pP[2], 0.0, 0.0, pP[3]);
        SetObjectMaterialText(ActorData[Actorid][ActorObject], " ");
    #else
        Actorid = CreateDynamicActor(skin_actor, pP[0], pP[1], pP[2], pP[3], _, _, GetPlayerVirtualWorld(playerid));
        if(!IsValidDynamicActor(Actorid)) return SendClientMessage(playerid, -1, "{FF0000}Ocorreu um erro. Provavelmente o máximo de actors foi atingido!");
        if(Actorid >= MAX_ACTORS) return DestroyDynamicActor(Actorid), SendClientMessage(playerid, -1, "{FF0000}Você atingiu o limite de actors.");
        format(Msg, 144, "%s (%i)", Nome, Actorid);
        ActorData[Actorid][ActorLabel] = CreateDynamic3DTextLabel(Msg, 0xFFFF00AA, pP[0], pP[1], pP[2] + 1.0, 30.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, GetPlayerVirtualWorld(playerid));
        ActorData[Actorid][ActorObject] = CreateDynamicObject(1924, pP[0], pP[1], pP[2], 0.0, 0.0, pP[3]);
        SetDynamicObjectMaterialText(ActorData[Actorid][ActorObject], 0, " ");
    #endif
    ActorData[Actorid][ActorSkin] = skin_actor;
    format(ActorData[Actorid][ActorNome], 32, Nome);
    format(Msg, 144, "{FFFF00}Actor id: %i (Skin: %i) (Nome: %s)", Actorid, skin_actor, Nome);
    SendClientMessage(playerid, -1, Msg);
    SetPlayerPos(playerid, pP[0] + 1.0, pP[1] + 1.0, pP[2]);
    return 1;
}
CMD:destruiractor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, Msg[144];
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use: /destruiractor [actor id]");
    #if !defined USE_STREAMER
        if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
        DestroyActor(actorid);
        Delete3DTextLabel(ActorData[actorid][ActorLabel]);
        DestroyObject(ActorData[actorid][ActorObject]);
    #else
        if(!IsValidDynamicActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
        DestroyDynamicActor(actorid);
        DestroyDynamic3DTextLabel(ActorData[actorid][ActorLabel]);
        DestroyDynamicObject(ActorData[actorid][ActorObject]);
    #endif
    format(Msg, 144, "{FFFF00}Actor %s (%i) foi destruido.", ActorData[actorid][ActorNome], actorid);
    SendClientMessage(playerid, -1, Msg);
    ActorData[actorid][ActorSkin] = -1;
    format(ActorData[actorid][ActorNome], 32, "");
    return 1;
}
CMD:destruirtodosactors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new Msg[144], actors, amax;
    #if !defined USE_STREAMER
        amax = GetActorPoolSize();
    #else
        amax = Streamer_CountItems(STREAMER_TYPE_ACTOR, 1);
    #endif
    for(new i; i <= amax; i++) {
        if(ActorData[i][ActorSkin] == -1) continue;
        #if !defined USE_STREAMER
            if(!IsValidActor(i)) continue;
            Delete3DTextLabel(ActorData[i][ActorLabel]);
            DestroyObject(ActorData[i][ActorObject]);
            DestroyActor(i);
        #else
            if(!IsValidDynamicActor(i)) continue;
            DestroyDynamic3DTextLabel(ActorData[i][ActorLabel]);
            DestroyDynamicObject(ActorData[i][ActorObject]);
            DestroyDynamicActor(i);
        #endif
        ActorData[i][ActorSkin] = -1;
        format(ActorData[i][ActorNome], 32, "");
        actors++;
    }
    if(actors==0) return SendClientMessage(playerid, -1, "{FF0000}Não há actors!");
    format(Msg, 144, "{FFFF00}Foram destruidos %i actors.", actors);
    return SendClientMessage(playerid, -1, Msg);
}
CMD:animaractor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, animlib[32], animname[32], loop, Msg[144];
    if(sscanf(params, "is[32]s[32]i", actorid, animlib, animname, loop)) return SendClientMessage(playerid, -1, "{FF0000}Use: /animaractor [actor id] [animlib] [animname] [loop (0-1)");
    #if !defined USE_STREAMER
        if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
        ClearActorAnimations(actorid);
        ApplyActorAnimation(actorid, animlib, animname, 4.1, loop, 1, 1, 0, 0);
    #else
        if(!IsValidDynamicActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
        ClearDynamicActorAnimations(actorid);
        ApplyDynamicActorAnimation(actorid, animlib, animname, 4.1, loop, 1, 1, 0, 0);
    #endif
    format(Msg, 144, "{00FF00}Actor %s (%i) executando animação da lib %s animação %s (%s)", ActorData[actorid][ActorNome], actorid, animlib, animname, (loop == 0 ? ("sem loop") : ("com loop")));
    return SendClientMessage(playerid, -1, Msg);
}
CMD:pararanimactor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, Msg[144];
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use: /pararanimactor [actor id]");
    #if !defined USE_STREAMER
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    ClearActorAnimations(actorid);
    #else
    if(!IsValidDynamicActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    ClearDynamicActorAnimations(actorid);
    #endif
    format(Msg, 144, "{a9c4e4}Animação do actor %s (%i) foi parada!", ActorData[actorid][ActorNome], actorid);
    return SendClientMessage(playerid, -1, Msg);
}
CMD:animtodosactors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new animlib[32], animname[32], loop, Msg[144];
    if(sscanf(params, "s[32]s[32]i", animlib,animname,loop)) return SendClientMessage(playerid, -1, "{FF0000}Use: /animtodosactos [animlib] [animname] [loop (0-1)]");
    #if !defined USE_STREAMER
    for(new i; i <= GetActorPoolSize(); i++) {
        if(!IsValidActor(i)) continue;
        ClearActorAnimations(i);
        ApplyActorAnimation(i, animlib, animname, 4.1, loop, 1, 1, 0, 0);
    }
    #else
    for(new i; i <= Streamer_CountItems(STREAMER_TYPE_ACTOR, 1); i++) {
        if(!IsValidDynamicActor(i)) continue;
        ClearDynamicActorAnimations(i);
        ApplyDynamicActorAnimation(i, animlib, animname, 4.1, loop, 1, 1, 0, 0);
    }
    #endif
    format(Msg, 144, "{00FF00}Todos os actors estão executando a animação da lib %s animação %s (%s)", animlib, animname, (loop == 0 ? ("sem loop") : ("com loop")));
    return SendClientMessage(playerid, -1, Msg);
}
CMD:pararanimtodosactors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    #if !defined USE_STREAMER
    for(new i; i <= GetActorPoolSize(); i++) {
        if(!IsValidActor(i)) continue;
        ClearActorAnimations(i);
    }
    #else
    for(new i; i <= Streamer_CountItems(STREAMER_TYPE_ACTOR, 1); i++) {
        if(!IsValidDynamicActor(i)) continue;
        ClearDynamicActorAnimations(i);
    }
    #endif
    return SendClientMessage(playerid, -1, "{FFFF00}A animação de todos os actors existentes foram paradas.");
}
CMD:actorpos(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, Float:apos[4], Msg[144];
    if(sscanf(params, "iffff", actorid, apos[0], apos[1], apos[2], apos[3])) return SendClientMessage(playerid, -1, "{FF0000}Use: /actorpos [actorid] [x] [y] [z] [rotação]");
    #if !defined USE_STREAMER
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    DestroyObject(ActorData[actorid][ActorObject]);
    SetActorPos(actorid, apos[0], apos[1], apos[2]);
    SetActorFacingAngle(actorid, apos[3]);
    ActorData[actorid][ActorObject] = CreateObject(1924, apos[0], apos[1], apos[2], 0.0, 0.0, apos[3]);
    SetObjectMaterialText(ActorData[actorid][ActorObject], " ");
    Delete3DTextLabel(ActorData[actorid][ActorLabel]);
    format(Msg, 144, "%s (%i)", ActorData[actorid][ActorNome], actorid);
    ActorData[actorid][ActorLabel] = Create3DTextLabel(Msg, 0xFFFF00AA, apos[0], apos[1], apos[2] + 1.0, 30.0, GetActorVirtualWorld(actorid));
    #else
    if(!IsValidDynamicActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    DestroyDynamicObject(ActorData[actorid][ActorObject]);
    SetDynamicActorPos(actorid, apos[0], apos[1], apos[2]);
    SetDynamicActorFacingAngle(actorid, apos[3]);
    ActorData[actorid][ActorObject] = CreateDynamicObject(1924, apos[0], apos[1], apos[2], 0.0, 0.0, apos[3]);
    SetDynamicObjectMaterialText(ActorData[actorid][ActorObject], 0, " ");
    DestroyDynamic3DTextLabel(ActorData[actorid][ActorLabel]);
    format(Msg, 144, "%s (%i)", ActorData[actorid][ActorNome], actorid);
    ActorData[actorid][ActorLabel] = CreateDynamic3DTextLabel(Msg, 0xFFFF00AA, apos[0], apos[1], apos[2] + 1.0, 30.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, GetPlayerVirtualWorld(playerid));
    #endif
    format(Msg, 144, "{a9c4e4}Actor %s (%i) em x=%4.2f - y=%4.2f - z=%4.2f - rotação=%4.2f", ActorData[actorid][ActorNome], actorid, apos[0], apos[1], apos[2], apos[3]);
    return SendClientMessage(playerid, -1, Msg);
}
CMD:actormundo(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, amundo, Msg[144], Float:apos[3];
    if(sscanf(params, "ii", actorid, amundo)) return SendClientMessage(playerid, -1, "{FF0000}Use: /actormundo [actorid] [mundo]");
    #if !defined USE_STREAMER
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    GetActorPos(actorid, apos[0], apos[1], apos[2]);
    SetActorVirtualWorld(actorid, amundo);
    Delete3DTextLabel(ActorData[actorid][ActorLabel]);
    format(Msg, 144, "%s (%i)", ActorData[actorid][ActorNome], actorid);
    ActorData[actorid][ActorLabel] = Create3DTextLabel(Msg, 0xFFFF00AA, apos[0], apos[1], apos[2] + 1.0, 30.0, amundo);
    #else
    if(!IsValidDynamicActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    GetDynamicActorPos(actorid, apos[0], apos[1], apos[2]);
    SetDynamicActorVirtualWorld(actorid, amundo);
    DestroyDynamic3DTextLabel(ActorData[actorid][ActorLabel]);
    format(Msg, 144, "%s (%i)", ActorData[actorid][ActorNome], actorid);
    ActorData[actorid][ActorLabel] = CreateDynamic3DTextLabel(Msg, 0xFFFF00AA, apos[0], apos[1], apos[2] + 1.0, 30.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, amundo);
    #endif
    format(Msg, 144, "{a9c4e4}Actor %s (%i) em mundo %i.", ActorData[actorid][ActorNome], actorid, amundo);
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:actorvuneravel(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, Msg[144];
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use:/actorvuneravel [actorid]");
    #if !defined USE_STREAMER
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    if(IsActorInvulnerable(actorid)) {
        SetActorInvulnerable(actorid, false);
        format(Msg, 144, "{FFFF00}Actor %s (%i) agora é vunerável.", ActorData[actorid][ActorNome], actorid);
    }
    else {
        SetActorInvulnerable(actorid, true);
        format(Msg, 144, "{FFFF00}Actor %s (%i) agora é invunerável.", ActorData[actorid][ActorNome], actorid);
    }
    #else
    if(!IsValidDynamicActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    if(IsDynamicActorInvulnerable(actorid)) {
        SetDynamicActorInvulnerable(actorid, false);
        format(Msg, 144, "{FFFF00}Actor %s (%i) agora é vunerável.", ActorData[actorid][ActorNome], actorid);
    }
    else {
        SetDynamicActorInvulnerable(actorid, true);
        format(Msg, 144, "{FFFF00}Actor %s (%i) agora é invunerável.", ActorData[actorid][ActorNome], actorid);
    }
    #endif
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:actorvida(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, Float:avida, Msg[144];
    if(sscanf(params, "if", actorid, avida)) return SendClientMessage(playerid, -1, "{FF0000}Use: /actorvida [actorid] [vida]");
    #if !defined USE_STREAMER
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    SetActorHealth(actorid, avida);
    #else
    if(!IsValidDynamicActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    SetDynamicActorHealth(actorid, avida);
    #endif
    format(Msg, 144, "{a9c4e4}Vida do actor %s (%i) foi setada para: %4.2f", ActorData[actorid][ActorNome], actorid, avida);
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:reviveractor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, Msg[144];
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use: /reviveractor [actorid]");
    if(!ResyncActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Ocorreu um erro e o actor não pode reviver :(");
    format(Msg, 144, "{FFFF00}Actor %s (%i) revivido!", ActorData[actorid][ActorNome], actorid);
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:nomeactor(playerid,params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, novoNome[32], Msg[144];
    if(sscanf(params, "is[32]", actorid, novoNome)) return SendClientMessage(playerid, -1, "{FF0000}Use: /nomeactor [actor id] [novo nome]");
    #if !defined USE_STREAMER
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    #else
    if(!IsValidDynamicActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    #endif
    if(!strcmp(ActorData[actorid][ActorNome], novoNome, true)) return SendClientMessage(playerid, -1, "{FF0000}O novo nome é o atual do actor!");
    format(Msg, 144, "{a9c4e4}Você alterou o nome do actor %s (%i) para %s.", ActorData[actorid][ActorNome], actorid, novoNome);
    SendClientMessage(playerid, -1, Msg);
    format(ActorData[actorid][ActorNome], 32, "%s", novoNome);
    format(Msg, 144, "%s (%i)", novoNome, actorid);
    #if !defined USE_STREAMER
    Update3DTextLabelText(ActorData[actorid][ActorLabel], 0xFFFF00AA, Msg);
    #else
    UpdateDynamic3DTextLabelText(ActorData[actorid][ActorLabel], 0xFFFF00AA, Msg);
    #endif
    return 1;
}
CMD:exportaractors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new arquivo_nome[128];
    if(sscanf(params, "s[128]", arquivo_nome)) return SendClientMessage(playerid, -1, "{FF0000}Use: /exportaractors [nome do arquivo.pwn]");
    if(fexist(arquivo_nome)) return SendClientMessage(playerid, -1, "{FF0000}Este arquivo existe no diretório. Por favor insira outro nome!");
    new File:pActor, str[100], Msg[144];
    pActor = fopen(arquivo_nome, io_append);
    #if !defined USE_STREAMER
    fwrite(pActor, "#include a_samp\r\n\r\n");
    format(str, sizeof(str), "new xActors[%i];\r\n", GetActorPoolSize() + 1);
    #else
    fwrite(pActor, "#include a_samp\r\n#include streamer\r\n\r\n");
    format(str, sizeof(str), "new xActors[%i];\r\n", Streamer_CountItems(STREAMER_TYPE_ACTOR, 1) + 1);
    #endif
    fwrite(pActor, str);
    fwrite(pActor, "\r\npublic OnFilterScriptInit()\r\n{\r\n");
    #if !defined USE_STREAMER
    for(new i; i <= GetActorPoolSize(); i++) {
        if(ActorData[i][ActorSkin] == -1) continue;
        new Float:posAc[4];
        GetActorPos(i, posAc[0], posAc[1], posAc[2]);
        GetActorFacingAngle(i, posAc[3]);
        format(str, sizeof(str), "\txActors[%i] = CreateActor(%i, %4.2f, %4.2f, %4.2f, %4.2f); // %s \r\n", i, ActorData[i][ActorSkin], posAc[0], posAc[1], posAc[2], posAc[3], ActorData[i][ActorNome]);
        fwrite(pActor, str);
    }
    fwrite(pActor, "\tprint(\"[FS EXPORTADO] Actors criados!\");\r\n\treturn 1;\r\n}\r\n");
    fwrite(pActor, "public OnFilterScriptExit()\r\n{\r\n\tfor(new x; x < sizeof(xActors); x++) {\r\n\
                    \t\tDestroyActor(xActors[x]);\r\n\t}\r\n\treturn 1;\r\n}");
    #else
    for(new i; i <= Streamer_CountItems(STREAMER_TYPE_ACTOR, 1); i++) {
        if(ActorData[i][ActorSkin] == -1) continue;
        new Float:posAc[4];
        GetDynamicActorPos(i, posAc[0], posAc[1], posAc[2]);
        GetDynamicActorFacingAngle(i, posAc[3]);
        format(str, sizeof(str), "\txActors[%i] = CreateDynamicActor(%i, %4.2f, %4.2f, %4.2f, %4.2f, 1, 100.0, %i); // %s \r\n",ActorData[i][ActorSkin], posAc[0], posAc[1], posAc[2], posAc[3], ActorData[i][ActorNome], GetDynamicActorVirtualWorld(i));
        fwrite(pActor, str);
    }
    fwrite(pActor, "\tprint(\"[FS EXPORTADO] Actors dynamicos criados!\");\r\n\treturn 1;\r\n}\r\n");
    fwrite(pActor, "public OnFilterScriptExit()\r\n{\r\n\tfor(new x; x < sizeof(xActors); x++) {\r\n\
                    \t\tDestroyDynamicActor(xActors[x]);\r\n\t}\r\n\treturn 1;\r\n}");
    #endif

    fwrite(pActor, "\r\n\r\n/**************************************************\r\n\
                            Este FilterScript foi exportado pelo Test Actor\r\n\
                            \t\twww.brasilmegatrucker.com\r\n\
                            ***************************************************/");
    fclose(pActor);
    format(Msg, 144, "{a9c4e4}Exportado actors para o arquivo {ffffff}%s{a9c4e4} com sucesso!", arquivo_nome);
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:veractors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    SetPVarInt(playerid,"dialog_lista", 0);
    return VerActors(playerid);
}
CMD:comandosactor(playerid) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new di_actor[1500];
    strcat(di_actor, "Comando\tAbreviado\tDescrição\n");
    for(new i; i < sizeof(cmds_Actor); i++) {
        strcat(di_actor, cmds_Actor[i][Comando]);
        strcat(di_actor, "\t");
        strcat(di_actor, cmds_Actor[i][Abreviado]);
        strcat(di_actor, "\t");
        strcat(di_actor, cmds_Actor[i][Descricao]);
        strcat(di_actor, "\n");
    }
    return ShowPlayerDialog(playerid, DIALOG_ACTORCMDS, DIALOG_STYLE_TABLIST_HEADERS, "{FF0000}# {FFFFFF}Comando de actors", di_actor, "Ok", "");
}

CMD:editaractor(playerid, params[]) {
    new actorid, Msg[144];
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use: /editaractor [actorid]");
    #if !defined USE_STREAMER
    if(!IsValidActor(actorid) || !IsValidObject(ActorData[actorid][ActorObject])) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido para edição.");
    EditObject(playerid, ActorData[actorid][ActorObject]);
    #else
    if(!IsValidDynamicActor(actorid) || !IsValidDynamicObject(ActorData[actorid][ActorObject])) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido para edição.");
    EditDynamicObject(playerid, ActorData[actorid][ActorObject]);
    #endif
    format(Msg, sizeof(Msg), "{FFFF00}* Editando actor %s (%i)", ActorData[actorid][ActorNome], actorid);
    return SendClientMessage(playerid, -1, Msg);
}
// Retorno de Comandos
CMD:cac(playerid, params[]) return cmd_criaractor(playerid, params);
CMD:dac(playerid, params[]) return cmd_destruiractor(playerid, params);
CMD:dta(playerid, params[]) return cmd_destruirtodosactors(playerid, params);
CMD:ania(playerid, params[]) return cmd_animaractor(playerid, params);
CMD:pana(playerid, params[]) return cmd_pararanimactor(playerid, params);
CMD:anta(playerid, params[]) return cmd_animtodosactors(playerid, params);
CMD:panta(playerid, params[]) return cmd_pararanimtodosactors(playerid, params);
CMD:apos(playerid, params[]) return cmd_actorpos(playerid, params);
CMD:amun(playerid, params[]) return cmd_actormundo(playerid, params);
CMD:acin(playerid, params[]) return cmd_actorvuneravel(playerid, params);
CMD:acv(playerid, params[]) return cmd_actorvida(playerid, params);
CMD:reva(playerid, params[]) return cmd_reviveractor(playerid, params);
CMD:nac(playerid, params[]) return cmd_nomeactor(playerid, params);
CMD:eda(playerid, params[]) return cmd_editaractor(playerid, params);
CMD:va(playerid, params[]) return cmd_veractors(playerid, params);
CMD:exa(playerid, params[]) return cmd_exportaractors(playerid, params);
CMD:acmd(playerid) return cmd_comandosactor(playerid);

/////////////////////////////////////////////////////////////////////////////
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    switch (dialogid) {
        case DIALOG_ACTORCMDS: {
            if(!response) return 0;
            new Msg[144];
            format(Msg, 144, "{FFFF00}%s (%s): %s", cmds_Actor[listitem][Comando], cmds_Actor[listitem][Abreviado], cmds_Actor[listitem][Descricao]);
            SendClientMessage(playerid, -1, Msg);
            return 0;
        }
        case DIALOG_VERACTORS: {
            if(!response) return 0;
            new actors, Float:apos[4], Msg[144];
            if(listitem > 25) {
                SetPVarInt(playerid, "dialog_lista", GetPVarInt(playerid, "dialog_proxima_lista"));
                SetPVarInt(playerid, "dialog_proxima_lista", 0);
                VerActors(playerid);
                return 0;
            }
            #if !defined USE_STREAMER
            for(new i = GetPVarInt(playerid, "dialog_lista"); i <= GetActorPoolSize(); i++) {
                if(!IsValidActor(i)) continue;
                if(listitem == actors) {
                    GetActorPos(i, apos[0], apos[1], apos[2]);
                    GetActorFacingAngle(i, apos[3]);
                    SetPlayerPos(playerid, apos[0] + 1.0, apos[1] + 1.0, apos[2] + 1.5);
                    SetPlayerFacingAngle(i, apos[3]);
                    format(Msg, 144, "{a9c4e4}Você foi teleportado ao actor %s (%i)", ActorData[i][ActorNome], i);
                    SendClientMessage(playerid, -1, Msg);
                    break;
                }
                actors++;
            }
            #else
            for(new i = GetPVarInt(playerid, "dialog_lista"); i <= Streamer_CountItems(STREAMER_TYPE_ACTOR, 1); i++) {
                if(!IsValidDynamicActor(i)) continue;
                if(listitem == actors) {
                    GetDynamicActorPos(i, apos[0], apos[1], apos[2]);
                    GetDynamicActorFacingAngle(i, apos[3]);
                    SetPlayerPos(playerid, apos[0] + 1.0, apos[1] + 1.0, apos[2] + 1.5);
                    SetPlayerFacingAngle(i, apos[3]);
                    format(Msg, 144, "{a9c4e4}Você foi teleportado ao actor %s (%i)", ActorData[i][ActorNome], i);
                    SendClientMessage(playerid, -1, Msg);
                    break;
                }
                actors++;
            }
            #endif
            return 0;
        }
    }
    return 1;
}
#if !defined USE_STREAMER
public OnPlayerGiveDamageActor(playerid, damaged_actorid, Float:amount, weaponid, bodypart)
{
    if(!IsActorInvulnerable(damaged_actorid)) {
        new Float:aVida;
        GetActorHealth(damaged_actorid, aVida);
        SetActorHealth(damaged_actorid, aVida-amount);
    }
    return 1;
}
public OnPlayerEditObject(playerid, playerobject, objectid, response, Float:fX, Float:fY, Float:fZ, Float:fRotX, Float:fRotY, Float:fRotZ)
{
    if(playerobject) return 1;
    new Float:oldPos[6], Float:actorPos[4], Msg[144];
    GetObjectPos(objectid, oldPos[0], oldPos[1], oldPos[2]);
    GetObjectRot(objectid, oldPos[3], oldPos[4], oldPos[5]);
    for(new i; i <= GetActorPoolSize(); i++) {
        if(ActorData[i][ActorObject] == objectid) {
            GetActorPos(i, actorPos[0], actorPos[1], actorPos[2]);
            GetActorFacingAngle(i, actorPos[3]);
            switch(response) {
                case EDIT_RESPONSE_CANCEL:{
                    SetObjectPos(objectid, oldPos[0], oldPos[1], oldPos[2]);
                    SetObjectRot(objectid, oldPos[3], oldPos[4], oldPos[5]);
                    SetActorPos(i, actorPos[0], actorPos[1], actorPos[2]);
                    SetActorFacingAngle(i, actorPos[4]);
                }
                case EDIT_RESPONSE_UPDATE: {
                    SetActorPos(i, fX, fY, fZ);
                    SetActorFacingAngle(i, fRotZ);
                }
                case EDIT_RESPONSE_FINAL: {
                    SetActorPos(i, fX, fY, fZ);
                    SetActorFacingAngle(i, fRotZ);
                    SetObjectPos(objectid, fX, fY, fZ);
                    SetObjectRot(objectid, 0.0, 0.0, fRotZ);
                    Destroy3DTextLabel(ActorData[i][ActorLabel]);
                    format(Msg, sizeof(Msg), "%s (%i)", ActorData[i][ActorNome], i);
                    ActorData[i][ActorLabel] = Create3DTextLabel(Msg, 0xFFFF00AA, fX, fY, fZ + 1.0, 30.0, GetActorVirtualWorld(i));
                }
            }
            break;
        }
    }
    return 0;
}
#else
public OnPlayerGiveDamageDynamicActor(playerid, actorid, Float:amount, weaponid, bodypart) {
    if(!IsDynamicActorInvulnerable(actorid)) {
        new Float:aVida;
        GetDynamicActorHealth(actorid, aVida);
        SetDynamicActorHealth(actorid, aVida-amount);
    }
    return 1;
}
public OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz) {
    new Float:oldPos[6], Float:aPos[4], Msg[144];
    GetDynamicObjectPos(objectid, oldPos[0], oldPos[1], oldPos[2]);
    GetDynamicObjectRot(objectid, oldPos[3], oldPos[4], oldPos[5]);
    for(new i; i <= Streamer_CountItems(STREAMER_TYPE_ACTOR, 1); i++) {
        if(ActorData[i][ActorObject] == objectid) {
            GetDynamicActorPos(i, aPos[0], aPos[1], aPos[2]);
            GetDynamicActorFacingAngle(i, aPos[3]);
            switch(response) {
                case EDIT_RESPONSE_CANCEL:{
                    SetDynamicObjectPos(objectid, oldPos[0], oldPos[1], oldPos[2]);
                    SetDynamicObjectRot(objectid, oldPos[3], oldPos[4], oldPos[5]);
                    SetDynamicActorPos(i, aPos[0], aPos[1], aPos[2]);
                    SetDynamicActorFacingAngle(i, aPos[3]);
                }
                case EDIT_RESPONSE_UPDATE: {
                    SetDynamicActorPos(i, x, y, z);
                    SetDynamicActorFacingAngle(i, rz);
                }
                case EDIT_RESPONSE_FINAL: {
                    SetDynamicActorPos(i, x, y, z);
                    SetDynamicActorFacingAngle(i, rz);
                    SetDynamicObjectPos(objectid, x, y, z);
                    SetDynamicObjectRot(objectid, 0.0, 0.0, rz);
                    DestroyDynamic3DTextLabel(ActorData[i][ActorLabel]);
                    format(Msg, sizeof(Msg), "%s (%i)", ActorData[i][ActorNome], i);
                    ActorData[i][ActorLabel] = CreateDynamic3DTextLabel(Msg, 0xFFFF00AA, x, y, z + 1.0, 30.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, GetActorVirtualWorld(i));
                }
            }
            break;
        }
    }
    return 0;
}
#endif
public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    //printf("[DEBUG] OnPlayerWeaponShot(%i, %i, %i, %i, %f, %f, %f)", playerid, weaponid, hittype, hitid, fX, fY, fZ);
    return 1;
}
// Funções do FS
stock VerActors(playerid) {
    new di[2500], actors, Float:pA[3], Float:aVida;
    strcat(di, "Actor\tCoordenadas\tMundo\tVida\n");
    #if !defined USE_STREAMER
    for(new i = GetPVarInt(playerid, "dialog_lista"); i <= GetActorPoolSize(); i++) {
        if(!IsValidActor(i)) continue;
        if(actors > 25) {
            SetPVarInt(playerid, "dialog_proxima_lista", i);
            strcat(di, "{FFFF00}Próxima página\n");
            break;
        }
        GetActorPos(i, pA[0], pA[1], pA[2]);
        GetActorHealth(i, aVida);
        format(di, sizeof(di), "%s%s (id: %i) [skin: %i]\tx=%4.2f y=%4.2f z=%4.2f\t%i\t%4.2f\n", di,ActorData[i][ActorNome],ActorData[i][ActorSkin],i,pA[0],pA[1],pA[2],GetActorVirtualWorld(i),aVida);
        actors++;
    }
    #else
    for(new i = GetPVarInt(playerid, "dialog_lista"); i <= Streamer_CountItems(STREAMER_TYPE_ACTOR, 1); i++) {
        if(!IsValidDynamicActor(i)) continue;
        if(actors > 25) {
            SetPVarInt(playerid, "dialog_proxima_lista", i);
            strcat(di, "{FFFF00}Próxima página\n");
            break;
        }
        GetDynamicActorPos(i, pA[0], pA[1], pA[2]);
        GetDynamicActorHealth(i, aVida);
        format(di, sizeof(di), "%s%s (id: %i) [skin: %i]\tx=%4.2f y=%4.2f z=%4.2f\t%i\t%4.2f\n", di,ActorData[i][ActorNome],i,ActorData[i][ActorSkin],pA[0],pA[1],pA[2],GetDynamicActorVirtualWorld(i),aVida);
        actors++;
    }
    #endif
    if(actors==0) return SendClientMessage(playerid, -1, "{FF0000}Não há actors!");
    ShowPlayerDialog(playerid, DIALOG_VERACTORS, DIALOG_STYLE_TABLIST_HEADERS, "{FF0000}# {FFFFFF}Visualizando actors", di, "Ok", "Cancelar");
    return 1;
}
//by Emmet
stock ResyncActor(actorid)
{
    new Float:x,Float:y, Float:z, worldid;
    #if !defined USE_STREAMER
    if(IsValidActor(actorid))
    {
        worldid = GetActorVirtualWorld(actorid);
        GetActorPos(actorid, x, y, z);
        SetActorPos(actorid, 1000.0, -2000.0, 500.0);
        SetActorVirtualWorld(actorid, random(cellmax));
        SetTimerEx("RestoreActor", 850, 0, "iifff", actorid, worldid, x, y, z);
        return 1;
    }
    #else
    if(IsValidDynamicActor(actorid))
    {
        worldid = GetDynamicActorVirtualWorld(actorid);
        GetDynamicActorPos(actorid, x, y, z);
        SetDynamicActorPos(actorid, 1000.0, -2000.0, 500.0);
        SetDynamicActorVirtualWorld(actorid, random(cellmax));
        SetTimerEx("RestoreActor", 850, 0, "iifff", actorid, worldid, x, y, z);
        return 1;
    }
    #endif
    return 0;
}

forward RestoreActor(actorid, worldid, Float:x, Float:y, Float:z);
public RestoreActor(actorid, worldid, Float:x, Float:y, Float:z)
{
    #if !defined USE_STREAMER
    SetActorVirtualWorld(actorid, worldid);
    SetActorPos(actorid, x, y, z);
    SetActorHealth(actorid, 100.0);
    #else
    SetDynamicActorVirtualWorld(actorid, worldid);
    SetDynamicActorPos(actorid, x, y, z);
    SetDynamicActorHealth(actorid, 100.0);
    #endif
    return 1;
}

/*********************************************************************************************************
**********                                                                                    ************
**********                          Feito por Nícolas Corrêa                                  ************
**********                         www.brasilmegatrucker.com                                  ************
**********                                                                                    ************
*********************************************************************************************************/
