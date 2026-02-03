bool                                 abort     = false;
CGamePlaygroundUIConfig::EUISequence desiredSequence;
bool                                 local     = false;
bool                                 switching = false;
const string                         title     = "\\$36D" + Icons::Film + "\\$G Sequences";

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
                startnew(SetSequenceAsync);
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
            local = false
                or cast<CTrackManiaNetworkServerInfo>(App.Network.ServerInfo).CurGameModeStr.Contains("_Local")
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
    try {
        return tostring((GetApp().CurrentPlayground).UIConfigs[0].UISequence);
    } catch {
        return "null";
    }
}

void SetSequenceAsync() {
    if (switching) {
        return;
    }

    trace("changing sequence to " + tostring(desiredSequence));

    switching = true;

    auto App = cast<CTrackMania>(GetApp());

    CGamePlaygroundUIConfig::EUISequence pre;

    try {
        pre = App.PlaygroundScript.UIManager.UIAll.UISequence;
        App.PlaygroundScript.UIManager.UIAll.UISequence = desiredSequence;
    } catch {
        switching = false;
        return;
    }

    try {
        while (!App.PlaygroundScript.UIManager.UIAll.UISequenceIsCompleted) {
            if (abort) {
                abort = false;
                break;
            }

            yield();
        }
    } catch { }

    try {
        trace("changing sequence back to " + tostring(pre));
        App.PlaygroundScript.UIManager.UIAll.UISequence = pre;
    } catch { }

    switching = false;
}
