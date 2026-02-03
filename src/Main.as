bool                                 abort     = false;
CGamePlaygroundUIConfig::EUISequence desiredSequence;
string                               CurGameModeStr;
bool                                 local     = false;
bool                                 switching = false;
string                               title     = "\\$36D" + Icons::Film + "\\$G Sequences";

void RenderMenu() {
    if (UI::BeginMenu(title, local)) {
        if (UI::MenuItem(
            "\\$F33" + Icons::Times + (switching ? "\\$G" : "\\$888") + " Abort",
            "",
            false,
            switching
        )) {
            abort = true;
        }

        string currentSequence = GetSequence();

        for (uint i = 0; i < 12; i++) {
            auto seq = CGamePlaygroundUIConfig::EUISequence(i);
            string seqStr = tostring(seq);
            bool isCurrent = seqStr == currentSequence;

            if (UI::MenuItem(
                (isCurrent
                    ? "\\$3F3" + Icons::Play + "\\$888 "
                    : "\\$36D" + Icons::Film + (switching ? "\\$888 " : "\\$G ")
                ) + seqStr,
                "",
                false,
                (true
                    and !isCurrent
                    and !switching
                )
            )) {
                desiredSequence = seq;
                startnew(SetSequence);
            }
        }

        UI::EndMenu();
    }
}

void Main() {
    auto App = cast<CTrackMania>(GetApp());

    while (true) {
        if (true
            and App.RootMap !is null
            and cast<CSmArenaClient>(App.CurrentPlayground) !is null
        ) {
            auto Network = cast<CTrackManiaNetwork>(App.Network);
            if (Network !is null) {
                auto ServerInfo = cast<CTrackManiaNetworkServerInfo>(Network.ServerInfo);
                if (ServerInfo !is null) {
                    CurGameModeStr = ServerInfo.CurGameModeStr;
                }
            } else {
                CurGameModeStr = "none";
            }

            local = false
                or CurGameModeStr.Contains("_Local")
                or (true
                    and App.Editor !is null
                    and App.PlaygroundScript !is null
                )
            ;
        } else {
            local = false;
        }

        yield();
    }
}

string GetSequence() {
    auto App = cast<CTrackMania>(GetApp());

    auto Playground = cast<CSmArenaClient>(App.CurrentPlayground);
    if (false
        or Playground is null
        or Playground.UIConfigs.Length == 0
    ) {
        return "null";
    }

    CGamePlaygroundUIConfig@ Config = Playground.UIConfigs[0];
    if (Config is null) {
        return "null";
    }

    return tostring(Config.UISequence);
}

void SetSequence() {
    if (switching) {
        return;
    }

    switching = true;

    auto App = cast<CTrackMania>(GetApp());

    auto Script = cast<CSmArenaRulesMode>(App.PlaygroundScript);
    if (Script is null) {
        switching = false;
        return;
    }

    CGamePlaygroundUIConfigMgrScript@ Manager = Script.UIManager;
    if (Manager is null) {
        switching = false;
        return;
    }

    CGamePlaygroundUIConfig@ Config = Manager.UIAll;
    if (Config is null) {
        switching = false;
        return;
    }

    CGamePlaygroundUIConfig::EUISequence Sequence = Config.UISequence;
    Config.UISequence = desiredSequence;

    while (!Config.UISequenceIsCompleted) {
        if (abort) {
            abort = false;
            break;
        }

        yield();
    }

    Config.UISequence = Sequence;

    switching = false;
}
