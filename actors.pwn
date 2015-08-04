#include <a_samp>
#include <zcmd>
#include <sscanf2>

#define DIALOG_ACTORCMDS 32002
#define DIALOG_VERACTORS 32003

enum cmd_infos
{
    Comando[128],
    Descricao[128]
};
new cmds_Actor[][cmd_infos] = {
    {"/criaractor [skin id] [nome]", "Cria um actor com a skin desejada e com um nome"},
    {"/destruiractor [actor id]", "Destroi um actor"},
    {"/destruirtodosactors", "Destrói todos os actors do servidor"},
    {"/animaractor [actor id] [animlib] [animname] [loop]", "Anima um actor"},
    {"/pararanimactor [actor id]", "Para a animação de um actor"},
    {"/animtodosactors [animlib] [animname] [loop]", "Anima todos os actors do servidor"},
    {"/pararanimtodosactors", "Para a animação de todos os actors"},
    {"/actorpos [actor id] [x] [y] [z] [rotação]", "Seta a posição de um actor"},
    {"/actormundo [actor id] [mundo virtual]", "Seta o mundo virtual de um actor"},
    {"/actorvuneravel [actor id]", "Deixa um actor vuneravel/invuneravel"},
    {"/actorvida [actor id] [vida]", "Seta a vida de um actor"},
    {"/reviveractor [actor id]", "Revive um actor"},
    {"/alteraractornome [actor id] [novo nome]", "Altera o nome de um actor"},
    {"/veractors", "Visualiza os actors criados"},
    {"/exportaractors [arquivo.pwn]", "Gera um script semi-pronto para uso dos actors criados"}
};

enum i_actor
{
    ActorNome[32],
    ActorSkin,
    Text3D:ActorLabel
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
    print("*****************************************");
	return 1;
}

public OnFilterScriptExit()
{
    for(new i; i <= GetActorPoolSize(); i++) {
        if(!IsValidActor(i)) continue;
        if(ActorData[i][ActorSkin] != -1) {
            DestroyActor(i);
            ActorData[i][ActorSkin] = -1;
            Delete3DTextLabel(ActorData[i][ActorLabel]);
            format(ActorData[i][ActorNome], 32, "");
        }
    }
    print("*****************************************");
    print("**** Actor debug - básico [DESLIGADO]****");
    print("*****************************************");
	return 1;
}


CMD:criaractor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new skin_actor, Nome[32];
    if(sscanf(params, "is[32]", skin_actor, Nome)) return SendClientMessage(playerid, -1, "{FF0000}Use: /criaractor [skin id] [nome]");
    if(skin_actor < 0 || skin_actor > 311) return SendClientMessage(playerid, -1, "{FF0000}O id é inválido!");
    new Float:pP[4], Msg[144], Actorid;
    GetPlayerPos(playerid, pP[0], pP[1], pP[2]);
    GetPlayerFacingAngle(playerid, pP[3]);
    Actorid = CreateActor(skin_actor, pP[0], pP[1], pP[2], pP[3]);
    if(!IsValidActor(Actorid)) return SendClientMessage(playerid, -1, "{FF0000}Ocorreu um erro. Provavelmente o máximo de actors foi atingido!");
    ActorData[Actorid][ActorSkin] = skin_actor;
    format(ActorData[Actorid][ActorNome], 32, Nome);
    format(Msg, 144, "{FFFF00}Actor id: %i (Skin: %i) (Nome: %s)", Actorid, skin_actor, Nome);
    SendClientMessage(playerid, -1, Msg);
    SetActorVirtualWorld(Actorid, GetPlayerVirtualWorld(playerid));
    format(Msg, 144, "%s (%i)", Nome, Actorid);
    ActorData[Actorid][ActorLabel] = Create3DTextLabel(Msg, 0xFFFF00AA, pP[0], pP[1], pP[2] + 1.0, 30.0, GetPlayerVirtualWorld(playerid));
    SetPlayerPos(playerid, pP[0] + 1.0, pP[1] + 1.0, pP[2]);
    return 1;
}
CMD:destruiractor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid;
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use: /destruiractor [actor id]");
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    new Msg[144];
    DestroyActor(actorid);
    format(Msg, 144, "{FFFF00}Actor %s (%i) foi destruido.", ActorData[actorid][ActorNome], actorid);
    SendClientMessage(playerid, -1, Msg);
    ActorData[actorid][ActorSkin] = -1;
    Delete3DTextLabel(ActorData[actorid][ActorLabel]);
    format(ActorData[actorid][ActorNome], 32, "");
    return 1;
}
CMD:destruirtodosactors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new Msg[144], actors;
    for(new i; i <= GetActorPoolSize(); i++) {
        if(!IsValidActor(i)) continue;
        DestroyActor(i);
        ActorData[i][ActorSkin] = -1;
        Delete3DTextLabel(ActorData[i][ActorLabel]);
        format(ActorData[i][ActorNome], 32, "");
        actors++;
    }
    if(actors==0) return SendClientMessage(playerid, -1, "{FF0000}Não há actors!");
    format(Msg, 144, "{FFFF00}Foram destruidos %i actors.", actors);
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:animaractor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, animlib[32], animname[32], loop;
    if(sscanf(params, "is[32]s[32]i", actorid, animlib, animname, loop)) return SendClientMessage(playerid, -1, "{FF0000}Use: /animaractor [actor id] [animlib] [animname] [loop (0-1)");
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    new Msg[144];
    ClearActorAnimations(actorid);
    ApplyActorAnimation(actorid, animlib, animname, 4.1, loop, 1, 1, 0, 0);
    format(Msg, 144, "{00FF00}Actor %s (%i) executando animação da lib %s animação %s (%s)", ActorData[actorid][ActorNome], actorid, animlib, animname, (loop == 0 ? ("sem loop") : ("com loop")));
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:pararanimactor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid;
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use: /pararanimactor [actor id]");
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    new Msg[144];
    ClearActorAnimations(actorid);
    format(Msg, 144, "{a9c4e4}Animação do actor %s (%i) foi parada!", ActorData[actorid][ActorNome], actorid);
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:animtodosactors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new animlib[32], animname[32], loop;
    if(sscanf(params, "s[32]s[32]i", animlib,animname,loop)) return SendClientMessage(playerid, -1, "{FF0000}Use: /animtodosactos [animlib] [animname] [loop (0-1)]");
    new Msg[144];
    for(new i; i <= GetActorPoolSize(); i++) {
        if(!IsValidActor(i)) continue;
        ClearActorAnimations(i);
        ApplyActorAnimation(i, animlib, animname, 4.1, loop, 1, 1, 0, 0);
    }
    format(Msg, 144, "{00FF00}Todos os actors estão executando a animação da lib %s animação %s (%s)", animlib, animname, (loop == 0 ? ("sem loop") : ("com loop")));
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:pararanimtodosactors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    for(new i; i <= GetActorPoolSize(); i++) {
        if(!IsValidActor(i)) continue;
        ClearActorAnimations(i);
    }
    SendClientMessage(playerid, -1, "{FFFF00}A animação de todos os actors existentes foram paradas.");
    return 1;
}
CMD:actorpos(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, Float:apos[4];
    if(sscanf(params, "iffff", actorid, apos[0], apos[1], apos[2], apos[3])) return SendClientMessage(playerid, -1, "{FF0000}Use: /actorpos [actorid] [x] [y] [z] [rotação]");
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    new Msg[144];
    SetActorPos(actorid, apos[0], apos[1], apos[2]);
    SetActorFacingAngle(actorid, apos[3]);
    format(Msg, 144, "{a9c4e4}Actor %s (%i) em x=%4.2f - y=%4.2f - z=%4.2f - rotação=%4.2f", ActorData[actorid][ActorNome], actorid, apos[0], apos[1], apos[2], apos[3]);
    SendClientMessage(playerid, -1, Msg);
    Delete3DTextLabel(ActorData[actorid][ActorLabel]);
    format(Msg, 144, "%s (%i)", ActorData[actorid][ActorNome], actorid);
    ActorData[actorid][ActorLabel] = Create3DTextLabel(Msg, 0xFFFF00AA, apos[0], apos[1], apos[2] + 1.0, 30.0, GetActorVirtualWorld(actorid));
    return 1;
}
CMD:actormundo(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, amundo;
    if(sscanf(params, "ii", actorid, amundo)) return SendClientMessage(playerid, -1, "{FF0000}Use: /actormundo [actorid] [mundo]");
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    new Msg[144], Float:apos[3];
    GetActorPos(actorid, apos[0], apos[1], apos[2]);
    SetActorVirtualWorld(actorid, amundo);
    format(Msg, 144, "{a9c4e4}Actor %s (%i) em mundo %i.", ActorData[actorid][ActorNome], actorid, amundo);
    SendClientMessage(playerid, -1, Msg);
    Delete3DTextLabel(ActorData[actorid][ActorLabel]);
    format(Msg, 144, "%s (%i)", ActorData[actorid][ActorNome], actorid);
    ActorData[actorid][ActorLabel] = Create3DTextLabel(Msg, 0xFFFF00AA, apos[0], apos[1], apos[2] + 1.0, 30.0, amundo);
    return 1;
}
CMD:actorvuneravel(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid;
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use:/actorvuneravel [actorid]");
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    new Msg[144];
    if(IsActorInvulnerable(actorid)) {
        SetActorInvulnerable(actorid, false);
        format(Msg, 144, "{FFFF00}Actor %s (%i) agora é vunerável.", ActorData[actorid][ActorNome], actorid);
    }
    else {
        SetActorInvulnerable(actorid, true);
        format(Msg, 144, "{FFFF00}Actor %s (%i) agora é invunerável.", ActorData[actorid][ActorNome], actorid);
    }
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:actorvida(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, Float:avida;
    if(sscanf(params, "if", actorid, avida)) return SendClientMessage(playerid, -1, "{FF0000}Use: /actorvida [actorid] [vida]");
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    new Msg[144];
    SetActorHealth(actorid, avida);
    format(Msg, 144, "{a9c4e4}Vida do actor %s (%i) foi setada para: %4.2f", ActorData[actorid][ActorNome], actorid, avida);
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:reviveractor(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid;
    if(sscanf(params, "i", actorid)) return SendClientMessage(playerid, -1, "{FF0000}Use: /reviveractor [actorid]");
    if(!ResyncActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Ocorreu um erro e o actor não pode reviver :(");
    new Msg[144];
    format(Msg, 144, "{FFFF00}Actor %s (%i) revivido!", ActorData[actorid][ActorNome], actorid);
    SendClientMessage(playerid, -1, Msg);
    return 1;
}
CMD:alteraractornome(playerid,params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new actorid, novoNome[32];
    if(sscanf(params, "is[32]", actorid, novoNome)) return SendClientMessage(playerid, -1, "{FF0000}Use: /alteraractornome [actor id] [novo nome]");
    if(!IsValidActor(actorid)) return SendClientMessage(playerid, -1, "{FF0000}Actor inválido.");
    if(!strcmp(ActorData[actorid][ActorNome], novoNome, true)) return SendClientMessage(playerid, -1, "{FF0000}O novo nome é o atual do actor!");
    new Msg[144];
    format(Msg, 144, "{a9c4e4}Você alterou o nome do actor %s (%i) para %s.", ActorData[actorid][ActorNome], actorid, novoNome);
    SendClientMessage(playerid, -1, Msg);
    format(ActorData[actorid][ActorNome], 32, "%s", novoNome);
    format(Msg, 144, "%s (%i)", novoNome, actorid);
    Update3DTextLabelText(ActorData[actorid][ActorLabel], 0xFFFF00AA, Msg);
    return 1;
}
CMD:exportaractors(playerid, params[]) {
    if(!IsPlayerAdmin(playerid)) return 0;
    new arquivo_nome[128];
    if(sscanf(params, "s[128]", arquivo_nome)) return SendClientMessage(playerid, -1, "{FF0000}Use: /exportaractors [nome do arquivo.pwn]");
    if(fexist(arquivo_nome)) return SendClientMessage(playerid, -1, "{FF0000}Este arquivo existe no diretório. Por favor insira outro nome!");
    new File:pActor, str[100], Msg[144];
    pActor = fopen(arquivo_nome, io_append);
    fwrite(pActor, "#include a_samp\r\n\r\n");
    format(str, sizeof(str), "new xActors[%i];\r\n", GetActorPoolSize() + 1);
    fwrite(pActor, str);
    fwrite(pActor, "\r\npublic OnFilterScriptInit()\r\n{\r\n");
    for(new i; i <= GetActorPoolSize(); i++) {
        new Float:posAc[4];
        GetActorPos(i, posAc[0], posAc[1], posAc[2]);
        GetActorFacingAngle(i, posAc[3]);
        format(str, sizeof(str), "\txActors[%i] = CreateActor(%i, %4.2f, %4.2f, %4.2f, %4.2f); // %s \r\n", i, ActorData[i][ActorSkin], posAc[0], posAc[1], posAc[2], posAc[3], ActorData[i][ActorNome]);
        fwrite(pActor, str);
    }
    fwrite(pActor, "\tprint(\"[FS EXPORTADO] Actors criados!\");\r\n\treturn 1;\r\n}\r\n");
    fwrite(pActor, "public OnFilterScriptExit()\r\n{\r\n\tfor(new x; x < sizeof(xActors); x++) {\r\n\
                    \t\tDestroyActor(xActors[x]);\r\n\t}\r\n\treturn 1;\r\n}");
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
    new di_actor[1000];
    strcat(di_actor, "Comando\tDescrição\n");
    for(new i; i < sizeof(cmds_Actor); i++) {
        strcat(di_actor, cmds_Actor[i][Comando]);
        strcat(di_actor, "\t");
        strcat(di_actor, cmds_Actor[i][Descricao]);
        strcat(di_actor, "\n");
    }
    ShowPlayerDialog(playerid, DIALOG_ACTORCMDS, DIALOG_STYLE_TABLIST_HEADERS, "{FF0000}# {FFFFFF}Comando de actors", di_actor, "Ok", "");
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    switch (dialogid) {
        case DIALOG_ACTORCMDS: {
            if(!response) return 0;
            new Msg[144];
            format(Msg, 144, "{FFFF00}%s - %s", cmds_Actor[listitem][Comando], cmds_Actor[listitem][Descricao]);
            SendClientMessage(playerid, -1, Msg);
            return 0;
        }
        case DIALOG_VERACTORS: {
            if(!response) return 0;
            new actors;
            if(listitem > 25) {
                SetPVarInt(playerid, "dialog_lista", GetPVarInt(playerid, "dialog_proxima_lista"));
                SetPVarInt(playerid, "dialog_proxima_lista", 0);
                VerActors(playerid);
                return 0;
            }
            for(new i = GetPVarInt(playerid, "dialog_lista"); i <= GetActorPoolSize(); i++) {
                if(!IsValidActor(i)) continue;
                if(listitem == actors) {
                    new Float:apos[4], Msg[144];
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
            return 0;
        }
    }
    return 1;
}

public OnPlayerGiveDamageActor(playerid, damaged_actorid, Float:amount, weaponid, bodypart)
{
    //printf("[DEBUG] OnPlayerGiveDamageActor(%i, %i, %f, %i, %i)", playerid, damaged_actorid, amount, weaponid, bodypart);
    if(!IsActorInvulnerable(damaged_actorid)) {
        new Float:aVida;
        GetActorHealth(damaged_actorid, aVida);
        SetActorHealth(damaged_actorid, aVida-amount);
        /*new Msg[144];
        format(Msg, 144, "{FF0000}* Actor %i sofreu %4.2f de dano. Agora ele tem %4.2f de vida.", damaged_actorid, amount, (aVida-amount));
        SendClientMessage(playerid, -1, Msg);    */
    }
    return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    //printf("[DEBUG] OnPlayerWeaponShot(%i, %i, %i, %i, %f, %f, %f)", playerid, weaponid, hittype, hitid, fX, fY, fZ);
    return 1;
}

stock VerActors(playerid) {
    new di[2500], actors;
    strcat(di, "Actor\tCoordenadas de Posição\tMundo - Skin\tVida\n");
    for(new i = GetPVarInt(playerid, "dialog_lista"); i <= GetActorPoolSize(); i++) {
        if(!IsValidActor(i)) continue;
        if(actors > 25) {
            SetPVarInt(playerid, "dialog_proxima_lista", i);
            strcat(di, "{FFFF00}Próxima página\n");
            break;
        }
        new Float:pA[3], Float:aVida;
        GetActorPos(i, pA[0], pA[1], pA[2]);
        GetActorHealth(i, aVida);
        format(di, sizeof(di), "%s%s (%i)\tx=%4.2f y=%4.2f z=%4.2f\t%i - %i\t%4.2f\n", di,ActorData[i][ActorNome], i,pA[0],pA[1],pA[2],GetActorVirtualWorld(i),ActorData[i][ActorSkin],aVida);
        actors++;
    }
    if(actors==0) return SendClientMessage(playerid, -1, "{FF0000}Não há actors!");
    ShowPlayerDialog(playerid, DIALOG_VERACTORS, DIALOG_STYLE_TABLIST_HEADERS, "{FF0000}# {FFFFFF}Visualizando actors", di, "Ok", "Cancelar");
    return 1;
}
//by Emmet
stock ResyncActor(actorid)
{
    if(IsValidActor(actorid))
    {
        new  Float:x,Float:y, Float:z,
        worldid = GetActorVirtualWorld(actorid);
        GetActorPos(actorid, x, y, z);
        SetActorPos(actorid, 1000.0, -2000.0, 500.0);
        SetActorVirtualWorld(actorid, random(cellmax));
        SetTimerEx("RestoreActor", 850, 0, "iifff", actorid, worldid, x, y, z);
        return 1;
    }
    return 0;
}

forward RestoreActor(actorid, worldid, Float:x, Float:y, Float:z);
public RestoreActor(actorid, worldid, Float:x, Float:y, Float:z)
{
    SetActorVirtualWorld(actorid, worldid);
    SetActorPos(actorid, x, y, z);
    SetActorHealth(actorid, 100.0);
    return 1;
}
