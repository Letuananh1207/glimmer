#pragma once
#include <TFT_eSPI.h>

// SmallTV palette — "warm dark" from the Claude Design system.
//
// RGB565 values computed from the design's source hex codes.
// Discipline: one accent color per screen. Surface / ink / muted are universal.
namespace Theme {
    // ── Surface ──
    // BG = pure black so the panel's color tuning doesn't tint it grey/cyan.
    // Design wanted #0E0D12 but that comes out as desaturated grey on this panel.
    constexpr uint16_t BG       = 0x0000;  // pure black
    constexpr uint16_t PANEL    = 0x20C5;  // #1F1A28 (lifted from design for more depth)
    constexpr uint16_t PANEL2   = 0x2907;  // #2A2236
    constexpr uint16_t LINE     = 0x3148;  // #34293F

    // ── Ink — punchier cream that reads cleanly on the panel ──
    constexpr uint16_t INK      = 0xFFBC;  // #FFF8E8 bright cream
    constexpr uint16_t INK_DIM  = 0xD676;  // #D8CDB8
    constexpr uint16_t MUTED    = 0x8BF2;  // #8A7F96

    // ── Accents — saturated so they punch on the warm-dark surface ──
    constexpr uint16_t CORAL    = 0xFA89;  // #FF5247  Claude
    constexpr uint16_t AMBER    = 0xFE88;  // #FFD23F  Clock
    constexpr uint16_t MINT     = 0x8F2E;  // #8FE574  Info / OK
    constexpr uint16_t SKY      = 0x55BF;  // #54B6FF  Weather
    constexpr uint16_t LILAC    = 0xC43F;  // #C385FF  Codex
    // Theme color for a named channel — the slide-progress bar at the bottom
    // of the active taskbar button (P-2026-11-26.8).
    uint16_t channelColor(const char* name);

    // ── XP (Luna) palette — P-2026-11-26.8/.9, token themeXP.color ──
    // Window chrome, taskbar, components and the system screens. Names drop
    // the token's "xp" prefix: xpBody → XP::BODY. Night face + boot keep BG.
    namespace XP {
        constexpr uint16_t WELCOME_BAND     = 0x0193;  // #00309C xpWelcomeBand
        constexpr uint16_t LINK             = 0x0339;  // #0066CC xpLink (P-2026-11-26.11)
        constexpr uint16_t TITLE_EDGE       = 0x01F6;  // #003DB5 xpTitleEdge
        constexpr uint16_t GROUP_LABEL      = 0x023A;  // #0046D5 xpGroupLabel
        constexpr uint16_t FRAME            = 0x023A;  // #0047D3 xpFrame
        constexpr uint16_t TITLE_DARK       = 0x025A;  // #0049D6 xpTitleDark
        constexpr uint16_t TITLE            = 0x02DD;  // #0058EE xpTitle
        constexpr uint16_t FLAG_BLUE        = 0x053E;  // #05A6F0 xpFlagBlue
        constexpr uint16_t TITLE_SHADOW     = 0x092D;  // #0A246A xpTitleShadow
        constexpr uint16_t SKY              = 0x0B59;  // #0A6ACF xpSky
        constexpr uint16_t TRAY             = 0x0C5D;  // #0F8BE8 xpTray
        constexpr uint16_t TRAY_EDGE        = 0x1215;  // #1042AF xpTrayEdge
        constexpr uint16_t BTN_PRESSED_EDGE = 0x11F2;  // #163E91 xpBtnPressedEdge
        constexpr uint16_t BOOT_BLOCK_LO    = 0x1A77;  // #1A4DB8 xpBootBlockLo
        constexpr uint16_t BTN_EDGE         = 0x1A99;  // #1A50C8 xpBtnEdge
        constexpr uint16_t TASK_DARK        = 0x1A77;  // #1C4FBF xpTaskDark
        constexpr uint16_t CHECK_BOX        = 0x1A90;  // #1C5180 xpCheckBox
        constexpr uint16_t BTN_PRESSED      = 0x1A76;  // #1E4FB5 xpBtnPressed
        constexpr uint16_t START_SHADOW     = 0x1AE3;  // #1E5E1E xpStartShadow
        constexpr uint16_t ICON_INFO        = 0x1B7C;  // #1F6FE0 xpIconInfo
        constexpr uint16_t CHECK            = 0x2504;  // #21A121 xpCheck
        constexpr uint16_t TASK             = 0x22FB;  // #245EDC xpTask
        constexpr uint16_t WELCOME_SHADOW   = 0x29F1;  // #2A3F8F xpWelcomeShadow
        constexpr uint16_t TITLE_LIGHT      = 0x2C1E;  // #2B80F5 xpTitleLight
        constexpr uint16_t USER_SEL         = 0x2AB8;  // #2C55C4 xpUserSel
        constexpr uint16_t START_DARK       = 0x2BE5;  // #2E7D2E xpStartDark
        constexpr uint16_t GREEN            = 0x2C45;  // #2E8A2E xpGreen
        constexpr uint16_t BOOT_BLOCK       = 0x2B7C;  // #2F6FE6 xpBootBlock
        constexpr uint16_t SELECT           = 0x3358;  // #316AC5 xpSelect
        constexpr uint16_t TASK_LIGHT       = 0x3BFD;  // #3A7DEB xpTaskLight
        constexpr uint16_t START            = 0x3CE7;  // #3A9E3A xpStart
        constexpr uint16_t BAND_EDGE        = 0x3A75;  // #3B4FA8 xpBandEdge
        constexpr uint16_t BTN              = 0x3C1E;  // #3C81F3 xpBtn
        constexpr uint16_t BAR              = 0x3E27;  // #3CC63C xpBar
        constexpr uint16_t TITLE_HI         = 0x3CBF;  // #3D95FF xpTitleHi
        constexpr uint16_t TRAY_HI          = 0x3D5E;  // #3FA9F5 xpTrayHi
        constexpr uint16_t LABEL            = 0x4A69;  // #4D4D4D xpLabel
        constexpr uint16_t SELECT_CLAWD     = 0x8393;  // #85719E xpSelectClawd — selected Clawd icon (P-2026-11-26.14)
        constexpr uint16_t WELCOME          = 0x5BFB;  // #5A7EDC xpWelcome
        constexpr uint16_t TASK_HI          = 0x5CDE;  // #5A9BF6 xpTaskHi
        constexpr uint16_t START_HI         = 0x5E0B;  // #5CC15C xpStartHi
        constexpr uint16_t USER_SEL_HI      = 0x5C3C;  // #5F84E3 xpUserSelHi
        constexpr uint16_t MUTED            = 0x6B6D;  // #6F6F6F xpMuted
        constexpr uint16_t LILAC            = 0x7A39;  // #7A44C8 xpLilac
        constexpr uint16_t DIVIDER_FADE     = 0x7CDD;  // #7D9BE8 xpDividerFade
        constexpr uint16_t FIELD_BORDER     = 0x7CF7;  // #7F9DB9 xpFieldBorder
        constexpr uint16_t WELCOME_LINE     = 0x7D3E;  // #7FA4F0 xpWelcomeLine
        constexpr uint16_t CAPTION_OFF      = 0x7D3E;  // #7FA4F0 xpCaptionOff — □ of a window that never resizes (P-2026-11-26.14)
        constexpr uint16_t FLAG_GREEN       = 0x85E0;  // #81BC06 xpFlagGreen
        constexpr uint16_t LAPTOP           = 0x8410;  // #808080 xpLaptop — Clawd at work (P-2026-11-26.13)
        // Dò mìn (P-2026-11-27.25, token themeXP.mines): Windows 3D grey, LED, the number colours of XP.
        namespace Mines {
            constexpr uint16_t FACE      = 0xC618;  // #C0C0C0 body, cells
            constexpr uint16_t SHADE     = 0x8410;  // #808080 sunken / raised dark edge, open-cell rule
            constexpr uint16_t SMILE     = 0xFFE0;  // #FFFF00
            constexpr uint16_t LED_ON    = 0xF800;  // #FF0000
            constexpr uint16_t LED_OFF   = 0x4800;  // #480000
            constexpr uint16_t BLAST     = 0xF800;  // #FF0000 the mine clicked, wrong-flag cross
            constexpr uint16_t N[9] = {0x0000,
                0x001F,   // 1 #0000FF
                0x0400,   // 2 #008000
                0xF800,   // 3 #FF0000
                0x0010,   // 4 #000080
                0x8000,   // 5 #800000
                0x0410,   // 6 #008080
                0x0000,   // 7 black
                0x8410};  // 8 #808080
        }
        constexpr uint16_t SELECT_ICON      = 0x9DBC;  // #98B4E2 xpSelectIcon — selected desktop icon (P-2026-11-26.14)
        constexpr uint16_t BOOT_BLOCK_HI    = 0x9E1F;  // #9BC0FA xpBootBlockHi
        constexpr uint16_t BAND_EDGE_WARM   = 0x9B4D;  // #9C6A6A xpBandEdgeWarm
        constexpr uint16_t DIM              = 0xAD53;  // #ACA899 xpDim — XP disabled text (P-2026-11-26.11)
        constexpr uint16_t STATUS_LINE      = 0xAD53;  // #ACA899 xpStatusLine
        constexpr uint16_t MENU_BORDER      = 0xAD53;  // #ACA899 xpMenuBorder — menu frame, dim items
        constexpr uint16_t BOOT_GREY        = 0xB596;  // #B2B2B2 xpBootGrey
        constexpr uint16_t FLASH_EDGE       = 0xBB23;  // #B8661E xpFlashEdge
        constexpr uint16_t EMPTY_ICON       = 0xBDB4;  // #B8B4A0 xpEmptyIcon
        constexpr uint16_t DIVIDER          = 0xBE5E;  // #B9CBF5 xpDivider
        constexpr uint16_t RED              = 0xC125;  // #C1272D xpRed
        constexpr uint16_t AMBER            = 0xCC40;  // #C98A00 xpAmber
        constexpr uint16_t WELCOME_SUB      = 0xCEBE;  // #C9D6F7 xpWelcomeSub
        constexpr uint16_t GROUP            = 0xD697;  // #D0D0BF xpGroup
        constexpr uint16_t ICON_ERROR       = 0xD9A3;  // #D8341E xpIconError
        constexpr uint16_t ROW_HI           = 0xDF3F;  // #DCE6F8 xpRowHi
        constexpr uint16_t CLOSE            = 0xE287;  // #E0523C xpClose
        constexpr uint16_t ROW_LINE         = 0xE73C;  // #E4E4E4 xpRowLine
        constexpr uint16_t BODY             = 0xEF5B;  // #ECE9D8 xpBody
        constexpr uint16_t FLASH            = 0xF506;  // #F0A030 xpFlash
        constexpr uint16_t WELCOME_ORANGE   = 0xF465;  // #F28F2E xpWelcomeOrange
        constexpr uint16_t ICON_WARN        = 0xF600;  // #F2C200 xpIconWarn
        constexpr uint16_t USER_PIC         = 0xF60F;  // #F2C27A xpUserPic
        constexpr uint16_t FLAG_RED         = 0xF284;  // #F35325 xpFlagRed
        constexpr uint16_t FLAG_YELLOW      = 0xFDC1;  // #FFBA08 xpFlagYellow
        constexpr uint16_t INFO_BAR         = 0xFFFC;  // #FFFFE1 xpInfoBar
        constexpr uint16_t WHITE            = 0xFFFF;  // #FFFFFF white
        constexpr uint16_t BLACK            = 0x0000;  // #000000 body text
        // P-2026-11-27.24 (themeXP.hot, themeXP.turnOff): hot caption × / Tắt button lit,
        // Chờ button lit, Hủy button (XP push button).
        constexpr uint16_t CLOSE_HOT        = 0xF34A;  // #F06A50 xpClose hot
        constexpr uint16_t STANDBY_HI       = 0xFF30;  // #FFE680 Chờ lit
        constexpr uint16_t PUSH_EDGE        = 0x01EE;  // #003C74 push button edge
        constexpr uint16_t PUSH_FACE        = 0xF79D;  // #F4F3EE push button face
        constexpr uint16_t PUSH_SHADE       = 0xD698;  // #D6D0C5 push button bottom rows
    }
}
