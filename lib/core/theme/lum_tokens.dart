// GENERATED from Figma variables by abide-design-work/ds/export/gen_flutter_tokens.py.
// Do not edit by hand: change Figma, re-export, re-run the script.
// ignore_for_file: constant_identifier_names

import 'dart:ui' show Color, FontFeature, FontVariation, FontStyle, FontWeight;

import 'package:flutter/painting.dart' show TextStyle;

/// Lumway colour tokens (Figma collection "Color", modes Light and Dark).
class LumColors {
  const LumColors({
    required this.bgPage,
    required this.bgSurface,
    required this.bgSurfaceSunken,
    required this.bgPrimary,
    required this.bgPrimaryContainer,
    required this.bgSecondary,
    required this.bgSecondaryContainer,
    required this.bgAccentContainer,
    required this.bgSuccessContainer,
    required this.bgDanger,
    required this.bgDangerContainer,
    required this.bgDisabled,
    required this.bgInverse,
    required this.bgElevated,
    required this.bgGrouped,
    required this.bgGroupedCell,
    required this.bgFeature,
    required this.bgTonal,
    required this.bgAvatar,
    required this.bgProjection,
    required this.textPrimary,
    required this.textSecondary,
    required this.textBrand,
    required this.textAccent,
    required this.textDanger,
    required this.textDisabled,
    required this.textInverse,
    required this.textOnPrimary,
    required this.textOnPrimaryContainer,
    required this.textOnSecondary,
    required this.textOnSecondaryContainer,
    required this.textOnAccentContainer,
    required this.textOnSuccessContainer,
    required this.textOnDanger,
    required this.textOnDangerContainer,
    required this.textOnLamp,
    required this.textOnFeature,
    required this.textOnTonal,
    required this.textOnAvatar,
    required this.textOnEveningSky,
    required this.textOnProjection,
    required this.iconDefault,
    required this.iconSecondary,
    required this.iconBrand,
    required this.iconAccent,
    required this.iconOnPrimary,
    required this.iconSuccess,
    required this.iconDanger,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderFocus,
    required this.borderTonal,
    required this.statePressed,
    required this.stateFocusRing,
    required this.highlightSun,
    required this.highlightLeaf,
    required this.highlightSky,
    required this.highlightRose,
    required this.highlightLilac,
    required this.glassFill,
    required this.glassFillOpaque,
    required this.glassStroke,
    required this.glassEdgeShadow,
    required this.scrimEdge,
    required this.scrimPageClear,
    required this.controlSwitchOn,
    required this.controlSwitchOff,
    required this.controlSwitchLocked,
    required this.controlTrackOff,
    required this.controlKnob,
    required this.lampFlame,
    required this.lampFlameCore,
    required this.lampGlow,
    required this.lampBody,
    required this.lampOil,
    required this.lampUnlit,
    required this.lampMark,
    required this.qrModule,
    required this.qrTile,
    required this.mediaDim,
    required this.mediaOnDim,
    required this.liveBg,
    required this.liveOnBg,
    required this.liveContainer,
    required this.glowTint,
    required this.glowPageTl,
    required this.glowPageBr,
    required this.buttonPrimaryLip,
    required this.buttonGoldTop,
    required this.buttonGoldBottom,
    required this.buttonGoldLip,
    required this.buttonOnGold,
    required this.buttonSecondary,
    required this.buttonSecondaryLip,
    required this.buttonDangerLip,
    required this.tileSelected,
    required this.tileSelectedStroke,
    required this.tileOnSelected,
    required this.tileOnSelectedAccent,
    required this.tileOnSelectedSecondary,
    required this.tileStreak,
    required this.tileOnStreak,
    required this.tabActive,
    required this.chip,
    required this.sceneSkyTop,
    required this.sceneSkyMid,
    required this.sceneSkyHorizon,
    required this.sceneSun,
    required this.sceneStar,
    required this.sceneCloud,
    required this.sceneCloudShade,
    required this.sceneMountainTop,
    required this.sceneMountainBottom,
    required this.sceneHillFarTop,
    required this.sceneHillFarBottom,
    required this.sceneHaze,
    required this.sceneHillNearTop,
    required this.sceneHillNearBottom,
    required this.sceneHillRim,
    required this.sceneMeadowTop,
    required this.sceneMeadowBottom,
    required this.sceneRoad,
    required this.sceneRoadFar,
    required this.sceneRoadEdge,
    required this.sceneTreeLight,
    required this.sceneTreeDark,
    required this.sceneTreeHighlight,
    required this.sceneTreeTrunk,
    required this.sceneWaterTop,
    required this.sceneWaterBottom,
    required this.sceneWaterRim,
    required this.sceneFlowerPink,
    required this.sceneFlowerGold,
    required this.sceneShadow,
    required this.sceneGlow,
    required this.sceneEveningTop,
    required this.sceneEveningHorizon,
    required this.sceneEveningGround,
    required this.scenePanel,
    required this.sceneStopDoneTop,
    required this.sceneStopDoneBottom,
    required this.sceneStopDoneSide,
    required this.sceneStopDoneRim,
    required this.sceneStopCurrentTop,
    required this.sceneStopCurrentBottom,
    required this.sceneStopCurrentSide,
    required this.sceneStopCurrentRim,
    required this.sceneStopOnCurrent,
    required this.sceneStopUpcomingTop,
    required this.sceneStopUpcomingBottom,
    required this.sceneStopUpcomingSide,
    required this.sceneStopUpcomingRim,
    required this.sceneStopOnUpcoming,
    required this.sceneStopGraceTop,
    required this.sceneStopGraceBottom,
    required this.sceneStopGraceSide,
    required this.sceneStopGraceRim,
    required this.sceneStopHighlight,
    required this.sceneTravellerCloakTop,
    required this.sceneTravellerCloakBottom,
    required this.sceneTravellerRim,
    required this.sceneTravellerSkinTop,
    required this.sceneTravellerSkinBottom,
    required this.sceneTravellerScarf,
    required this.sceneTravellerScarfShade,
    required this.sceneTravellerSatchel,
    required this.sceneTravellerStrap,
    required this.sceneTravellerStaff,
    required this.sceneTravellerBoots,
    required this.sceneTravellerInk,
    required this.sceneTravellerHighlight,
    required this.sceneDuskSkyTop,
    required this.sceneDuskSkyMid,
    required this.sceneDuskSkyHorizon,
    required this.sceneDuskSun,
    required this.sceneDuskSunDisc,
    required this.sceneDuskLand,
    required this.sceneDuskScrim,
    required this.sceneReader,
    required this.sceneReaderGlow,
    required this.sceneMarker,
    required this.sceneSkyTopClear,
    required this.sceneSunClear,
    required this.sceneHazeClear,
    required this.sceneShadowClear,
    required this.sceneGlowClear,
    required this.sceneEveningClear,
    required this.scenePanelClear,
    required this.sceneDuskSunClear,
    required this.sceneDuskLandClear,
    required this.sceneDuskScrimClear,
    required this.sceneReaderGlowClear,
  });

  /// `color/bg/page`
  final Color bgPage;
  /// `color/bg/surface`
  final Color bgSurface;
  /// `color/bg/surface-sunken`
  final Color bgSurfaceSunken;
  /// `color/bg/primary`
  final Color bgPrimary;
  /// `color/bg/primary-container`
  final Color bgPrimaryContainer;
  /// `color/bg/secondary`
  final Color bgSecondary;
  /// `color/bg/secondary-container`
  final Color bgSecondaryContainer;
  /// `color/bg/accent-container`
  final Color bgAccentContainer;
  /// `color/bg/success-container`
  final Color bgSuccessContainer;
  /// `color/bg/danger`
  final Color bgDanger;
  /// `color/bg/danger-container`
  final Color bgDangerContainer;
  /// `color/bg/disabled`
  final Color bgDisabled;
  /// `color/bg/inverse`
  final Color bgInverse;
  /// `color/bg/elevated`
  final Color bgElevated;
  /// `color/bg/grouped`
  final Color bgGrouped;
  /// `color/bg/grouped-cell`
  final Color bgGroupedCell;
  /// `color/bg/feature`
  final Color bgFeature;
  /// `color/bg/tonal`
  final Color bgTonal;
  /// `color/bg/avatar`
  final Color bgAvatar;
  /// `color/bg/projection`
  final Color bgProjection;
  /// `color/text/primary`
  final Color textPrimary;
  /// `color/text/secondary`
  final Color textSecondary;
  /// `color/text/brand`
  final Color textBrand;
  /// `color/text/accent`
  final Color textAccent;
  /// `color/text/danger`
  final Color textDanger;
  /// `color/text/disabled`
  final Color textDisabled;
  /// `color/text/inverse`
  final Color textInverse;
  /// `color/text/on-primary`
  final Color textOnPrimary;
  /// `color/text/on-primary-container`
  final Color textOnPrimaryContainer;
  /// `color/text/on-secondary`
  final Color textOnSecondary;
  /// `color/text/on-secondary-container`
  final Color textOnSecondaryContainer;
  /// `color/text/on-accent-container`
  final Color textOnAccentContainer;
  /// `color/text/on-success-container`
  final Color textOnSuccessContainer;
  /// `color/text/on-danger`
  final Color textOnDanger;
  /// `color/text/on-danger-container`
  final Color textOnDangerContainer;
  /// `color/text/on-lamp`
  final Color textOnLamp;
  /// `color/text/on-feature`
  final Color textOnFeature;
  /// `color/text/on-tonal`
  final Color textOnTonal;
  /// `color/text/on-avatar`
  final Color textOnAvatar;
  /// `color/text/on-evening-sky`
  final Color textOnEveningSky;
  /// `color/text/on-projection`
  final Color textOnProjection;
  /// `color/icon/default`
  final Color iconDefault;
  /// `color/icon/secondary`
  final Color iconSecondary;
  /// `color/icon/brand`
  final Color iconBrand;
  /// `color/icon/accent`
  final Color iconAccent;
  /// `color/icon/on-primary`
  final Color iconOnPrimary;
  /// `color/icon/success`
  final Color iconSuccess;
  /// `color/icon/danger`
  final Color iconDanger;
  /// `color/border/subtle`
  final Color borderSubtle;
  /// `color/border/strong`
  final Color borderStrong;
  /// `color/border/focus`
  final Color borderFocus;
  /// `color/border/tonal`
  final Color borderTonal;
  /// `color/state/pressed`
  final Color statePressed;
  /// `color/state/focus-ring`
  final Color stateFocusRing;
  /// `color/highlight/sun`
  final Color highlightSun;
  /// `color/highlight/leaf`
  final Color highlightLeaf;
  /// `color/highlight/sky`
  final Color highlightSky;
  /// `color/highlight/rose`
  final Color highlightRose;
  /// `color/highlight/lilac`
  final Color highlightLilac;
  /// `color/glass/fill`
  final Color glassFill;
  /// `color/glass/fill-opaque`
  final Color glassFillOpaque;
  /// `color/glass/stroke`
  final Color glassStroke;
  /// `color/glass/edge-shadow`
  final Color glassEdgeShadow;
  /// `color/scrim/edge`
  final Color scrimEdge;
  /// `color/scrim/page-clear`
  final Color scrimPageClear;
  /// `color/control/switch-on`
  final Color controlSwitchOn;
  /// `color/control/switch-off`
  final Color controlSwitchOff;
  /// `color/control/switch-locked`
  final Color controlSwitchLocked;
  /// `color/control/track-off`
  final Color controlTrackOff;
  /// `color/control/knob`
  final Color controlKnob;
  /// `color/lamp/flame`
  final Color lampFlame;
  /// `color/lamp/flame-core`
  final Color lampFlameCore;
  /// `color/lamp/glow`
  final Color lampGlow;
  /// `color/lamp/body`
  final Color lampBody;
  /// `color/lamp/oil`
  final Color lampOil;
  /// `color/lamp/unlit`
  final Color lampUnlit;
  /// `color/lamp/mark`
  final Color lampMark;
  /// `color/qr/module`
  final Color qrModule;
  /// `color/qr/tile`
  final Color qrTile;
  /// `color/media/dim`
  final Color mediaDim;
  /// `color/media/on-dim`
  final Color mediaOnDim;
  /// `color/live/bg`
  final Color liveBg;
  /// `color/live/on-bg`
  final Color liveOnBg;
  /// `color/live/container`
  final Color liveContainer;
  /// `color/glow/tint`
  final Color glowTint;
  /// `color/glow/page-tl`
  final Color glowPageTl;
  /// `color/glow/page-br`
  final Color glowPageBr;
  /// `color/button/primary-lip`
  final Color buttonPrimaryLip;
  /// `color/button/gold-top`
  final Color buttonGoldTop;
  /// `color/button/gold-bottom`
  final Color buttonGoldBottom;
  /// `color/button/gold-lip`
  final Color buttonGoldLip;
  /// `color/button/on-gold`
  final Color buttonOnGold;
  /// `color/button/secondary`
  final Color buttonSecondary;
  /// `color/button/secondary-lip`
  final Color buttonSecondaryLip;
  /// `color/button/danger-lip`
  final Color buttonDangerLip;
  /// `color/tile/selected`
  final Color tileSelected;
  /// `color/tile/selected-stroke`
  final Color tileSelectedStroke;
  /// `color/tile/on-selected`
  final Color tileOnSelected;
  /// `color/tile/on-selected-accent`
  final Color tileOnSelectedAccent;
  /// `color/tile/on-selected-secondary`
  final Color tileOnSelectedSecondary;
  /// `color/tile/streak`
  final Color tileStreak;
  /// `color/tile/on-streak`
  final Color tileOnStreak;
  /// `color/tab/active`
  final Color tabActive;
  /// `color/chip`
  final Color chip;
  /// `scene/sky/top`
  final Color sceneSkyTop;
  /// `scene/sky/mid`
  final Color sceneSkyMid;
  /// `scene/sky/horizon`
  final Color sceneSkyHorizon;
  /// `scene/sun`
  final Color sceneSun;
  /// `scene/star`
  final Color sceneStar;
  /// `scene/cloud`
  final Color sceneCloud;
  /// `scene/cloud-shade`
  final Color sceneCloudShade;
  /// `scene/mountain/top`
  final Color sceneMountainTop;
  /// `scene/mountain/bottom`
  final Color sceneMountainBottom;
  /// `scene/hill-far/top`
  final Color sceneHillFarTop;
  /// `scene/hill-far/bottom`
  final Color sceneHillFarBottom;
  /// `scene/haze`
  final Color sceneHaze;
  /// `scene/hill-near/top`
  final Color sceneHillNearTop;
  /// `scene/hill-near/bottom`
  final Color sceneHillNearBottom;
  /// `scene/hill-rim`
  final Color sceneHillRim;
  /// `scene/meadow/top`
  final Color sceneMeadowTop;
  /// `scene/meadow/bottom`
  final Color sceneMeadowBottom;
  /// `scene/road`
  final Color sceneRoad;
  /// `scene/road-far`
  final Color sceneRoadFar;
  /// `scene/road-edge`
  final Color sceneRoadEdge;
  /// `scene/tree/light`
  final Color sceneTreeLight;
  /// `scene/tree/dark`
  final Color sceneTreeDark;
  /// `scene/tree/highlight`
  final Color sceneTreeHighlight;
  /// `scene/tree/trunk`
  final Color sceneTreeTrunk;
  /// `scene/water/top`
  final Color sceneWaterTop;
  /// `scene/water/bottom`
  final Color sceneWaterBottom;
  /// `scene/water/rim`
  final Color sceneWaterRim;
  /// `scene/flower/pink`
  final Color sceneFlowerPink;
  /// `scene/flower/gold`
  final Color sceneFlowerGold;
  /// `scene/shadow`
  final Color sceneShadow;
  /// `scene/glow`
  final Color sceneGlow;
  /// `scene/evening/top`
  final Color sceneEveningTop;
  /// `scene/evening/horizon`
  final Color sceneEveningHorizon;
  /// `scene/evening/ground`
  final Color sceneEveningGround;
  /// `scene/panel`
  final Color scenePanel;
  /// `scene/stop/done-top`
  final Color sceneStopDoneTop;
  /// `scene/stop/done-bottom`
  final Color sceneStopDoneBottom;
  /// `scene/stop/done-side`
  final Color sceneStopDoneSide;
  /// `scene/stop/done-rim`
  final Color sceneStopDoneRim;
  /// `scene/stop/current-top`
  final Color sceneStopCurrentTop;
  /// `scene/stop/current-bottom`
  final Color sceneStopCurrentBottom;
  /// `scene/stop/current-side`
  final Color sceneStopCurrentSide;
  /// `scene/stop/current-rim`
  final Color sceneStopCurrentRim;
  /// `scene/stop/on-current`
  final Color sceneStopOnCurrent;
  /// `scene/stop/upcoming-top`
  final Color sceneStopUpcomingTop;
  /// `scene/stop/upcoming-bottom`
  final Color sceneStopUpcomingBottom;
  /// `scene/stop/upcoming-side`
  final Color sceneStopUpcomingSide;
  /// `scene/stop/upcoming-rim`
  final Color sceneStopUpcomingRim;
  /// `scene/stop/on-upcoming`
  final Color sceneStopOnUpcoming;
  /// `scene/stop/grace-top`
  final Color sceneStopGraceTop;
  /// `scene/stop/grace-bottom`
  final Color sceneStopGraceBottom;
  /// `scene/stop/grace-side`
  final Color sceneStopGraceSide;
  /// `scene/stop/grace-rim`
  final Color sceneStopGraceRim;
  /// `scene/stop/highlight`
  final Color sceneStopHighlight;
  /// `scene/traveller/cloak-top`
  final Color sceneTravellerCloakTop;
  /// `scene/traveller/cloak-bottom`
  final Color sceneTravellerCloakBottom;
  /// `scene/traveller/rim`
  final Color sceneTravellerRim;
  /// `scene/traveller/skin-top`
  final Color sceneTravellerSkinTop;
  /// `scene/traveller/skin-bottom`
  final Color sceneTravellerSkinBottom;
  /// `scene/traveller/scarf`
  final Color sceneTravellerScarf;
  /// `scene/traveller/scarf-shade`
  final Color sceneTravellerScarfShade;
  /// `scene/traveller/satchel`
  final Color sceneTravellerSatchel;
  /// `scene/traveller/strap`
  final Color sceneTravellerStrap;
  /// `scene/traveller/staff`
  final Color sceneTravellerStaff;
  /// `scene/traveller/boots`
  final Color sceneTravellerBoots;
  /// `scene/traveller/ink`
  final Color sceneTravellerInk;
  /// `scene/traveller/highlight`
  final Color sceneTravellerHighlight;
  /// `scene/dusk/sky-top`
  final Color sceneDuskSkyTop;
  /// `scene/dusk/sky-mid`
  final Color sceneDuskSkyMid;
  /// `scene/dusk/sky-horizon`
  final Color sceneDuskSkyHorizon;
  /// `scene/dusk/sun`
  final Color sceneDuskSun;
  /// `scene/dusk/sun-disc`
  final Color sceneDuskSunDisc;
  /// `scene/dusk/land`
  final Color sceneDuskLand;
  /// `scene/dusk/scrim`
  final Color sceneDuskScrim;
  /// `scene/reader`
  final Color sceneReader;
  /// `scene/reader-glow`
  final Color sceneReaderGlow;
  /// `scene/marker`
  final Color sceneMarker;
  /// `scene/sky/top-clear`
  final Color sceneSkyTopClear;
  /// `scene/sun-clear`
  final Color sceneSunClear;
  /// `scene/haze-clear`
  final Color sceneHazeClear;
  /// `scene/shadow-clear`
  final Color sceneShadowClear;
  /// `scene/glow-clear`
  final Color sceneGlowClear;
  /// `scene/evening-clear`
  final Color sceneEveningClear;
  /// `scene/panel-clear`
  final Color scenePanelClear;
  /// `scene/dusk/sun-clear`
  final Color sceneDuskSunClear;
  /// `scene/dusk/land-clear`
  final Color sceneDuskLandClear;
  /// `scene/dusk/scrim-clear`
  final Color sceneDuskScrimClear;
  /// `scene/reader-glow-clear`
  final Color sceneReaderGlowClear;

  static const light = LumColors(
    bgPage: Color(0xFFEDEFF2),
    bgSurface: Color(0xC7FFFFFF),
    bgSurfaceSunken: Color(0x0F141820),
    bgPrimary: Color(0xFF14171C),
    bgPrimaryContainer: Color(0x24D9A13B),
    bgSecondary: Color(0xFF4C515C),
    bgSecondaryContainer: Color(0x0F141820),
    bgAccentContainer: Color(0x24D9A13B),
    bgSuccessContainer: Color(0x1F287A48),
    bgDanger: Color(0xFF9D2019),
    bgDangerContainer: Color(0x1A9D2019),
    bgDisabled: Color(0x0F141820),
    bgInverse: Color(0xFF14171C),
    bgElevated: Color(0xFFEDEEEF),
    bgGrouped: Color(0xFFEDEFF2),
    bgGroupedCell: Color(0xC7FFFFFF),
    bgFeature: Color(0xFF37455E),
    bgTonal: Color(0xFFFEF4F1),
    bgAvatar: Color(0xFFF6D5A9),
    bgProjection: Color(0xFF16110A),
    textPrimary: Color(0xFF14171C),
    textSecondary: Color(0xFF4C515C),
    textBrand: Color(0xFF14171C),
    textAccent: Color(0xFF6F4A07),
    textDanger: Color(0xFF9D2019),
    textDisabled: Color(0xFF8A909A),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    textOnPrimaryContainer: Color(0xFF14171C),
    textOnSecondary: Color(0xFFFFFFFF),
    textOnSecondaryContainer: Color(0xFF14171C),
    textOnAccentContainer: Color(0xFF6F4A07),
    textOnSuccessContainer: Color(0xFF1D5C37),
    textOnDanger: Color(0xFFFFFFFF),
    textOnDangerContainer: Color(0xFF9D2019),
    textOnLamp: Color(0xFF14171C),
    textOnFeature: Color(0xFFFFFFFF),
    textOnTonal: Color(0xFF8D3B23),
    textOnAvatar: Color(0xFF3D2600),
    textOnEveningSky: Color(0xFFFFFFFF),
    textOnProjection: Color(0xFFFEF9F3),
    iconDefault: Color(0xFF14171C),
    iconSecondary: Color(0xFF4C515C),
    iconBrand: Color(0xFF14171C),
    iconAccent: Color(0xFF6F4A07),
    iconOnPrimary: Color(0xFFFFFFFF),
    iconSuccess: Color(0xFF287A48),
    iconDanger: Color(0xFF9D2019),
    borderSubtle: Color(0x17141820),
    borderStrong: Color(0x8C141820),
    borderFocus: Color(0xFF6F4A07),
    borderTonal: Color(0xFFAD4E32),
    statePressed: Color(0x1A16110A),
    stateFocusRing: Color(0xFF26375E),
    highlightSun: Color(0xB3F2C94C),
    highlightLeaf: Color(0xA66FCF97),
    highlightSky: Color(0xA656CCF2),
    highlightRose: Color(0xA6EB7FA0),
    highlightLilac: Color(0xA6B79CED),
    glassFill: Color(0xC7FFFFFF),
    glassFillOpaque: Color(0xFFFBFBFC),
    glassStroke: Color(0x17141820),
    glassEdgeShadow: Color(0x1A141820),
    scrimEdge: Color(0xE0EDEFF2),
    scrimPageClear: Color(0x00EDEFF2),
    controlSwitchOn: Color(0xFF287A48),
    controlSwitchOff: Color(0xFF7A808B),
    controlSwitchLocked: Color(0xFF5B8A6C),
    controlTrackOff: Color(0x8C141820),
    controlKnob: Color(0xFFFFFFFF),
    lampFlame: Color(0xFFD9A13B),
    lampFlameCore: Color(0xFFF6DDA6),
    lampGlow: Color(0x4DD9A13B),
    lampBody: Color(0xFF4C515C),
    lampOil: Color(0xFFA8731F),
    lampUnlit: Color(0xFF8A909A),
    lampMark: Color(0xFF6F4A07),
    qrModule: Color(0xFF2B251E),
    qrTile: Color(0xFFFFFFFF),
    mediaDim: Color(0x59000000),
    mediaOnDim: Color(0xFFFFFFFF),
    liveBg: Color(0xFFC22A1C),
    liveOnBg: Color(0xFFFFFFFF),
    liveContainer: Color(0xFFFDE7E4),
    glowTint: Color(0xFF3B4A66),
    glowPageTl: Color(0x293B4A66),
    glowPageBr: Color(0x1A3B4A66),
    buttonPrimaryLip: Color(0xFF000000),
    buttonGoldTop: Color(0xFFE9B955),
    buttonGoldBottom: Color(0xFFD9A13B),
    buttonGoldLip: Color(0xFFA26C1A),
    buttonOnGold: Color(0xFF14171C),
    buttonSecondary: Color(0xFFFFFFFF),
    buttonSecondaryLip: Color(0x24141820),
    buttonDangerLip: Color(0xFF5E120D),
    tileSelected: Color(0xFF14171C),
    tileSelectedStroke: Color(0xFF14171C),
    tileOnSelected: Color(0xFFFFFFFF),
    tileOnSelectedAccent: Color(0xFFEAC578),
    tileOnSelectedSecondary: Color(0xFFC6CAD0),
    tileStreak: Color(0xFFE6B85C),
    tileOnStreak: Color(0xFF14171C),
    tabActive: Color(0x14141820),
    chip: Color(0xE0FFFFFF),
    sceneSkyTop: Color(0xFFBCD8EE),
    sceneSkyMid: Color(0xFFE2EDF3),
    sceneSkyHorizon: Color(0xFFF6F1E4),
    sceneSun: Color(0xF2FFF3CF),
    sceneStar: Color(0x00FFFFFF),
    sceneCloud: Color(0xFFFFFFFF),
    sceneCloudShade: Color(0xFFD3E1EC),
    sceneMountainTop: Color(0xFFB7CDE0),
    sceneMountainBottom: Color(0xFFD6E2EA),
    sceneHillFarTop: Color(0xFFC6DCCF),
    sceneHillFarBottom: Color(0xFFA8C8B6),
    sceneHaze: Color(0xBFF4EFE3),
    sceneHillNearTop: Color(0xFFA4D38D),
    sceneHillNearBottom: Color(0xFF72B06A),
    sceneHillRim: Color(0xFFE2F5BB),
    sceneMeadowTop: Color(0xFF8CC576),
    sceneMeadowBottom: Color(0xFF5C9C56),
    sceneRoad: Color(0xFFF8EDD5),
    sceneRoadFar: Color(0xFFF4EFE3),
    sceneRoadEdge: Color(0xFFCFAE7F),
    sceneTreeLight: Color(0xFF7CC070),
    sceneTreeDark: Color(0xFF3F8A52),
    sceneTreeHighlight: Color(0xFFC2EBA0),
    sceneTreeTrunk: Color(0xFF8A6544),
    sceneWaterTop: Color(0xFF9FD3EC),
    sceneWaterBottom: Color(0xFF4F9DCC),
    sceneWaterRim: Color(0xFFEEF9FD),
    sceneFlowerPink: Color(0xFFF4C9D0),
    sceneFlowerGold: Color(0xFFF3D27A),
    sceneShadow: Color(0x6624402C),
    sceneGlow: Color(0xCCFFD76E),
    sceneEveningTop: Color(0x8C2F3560),
    sceneEveningHorizon: Color(0x80E9A877),
    sceneEveningGround: Color(0x592A2B48),
    scenePanel: Color(0xFFF7F8FA),
    sceneStopDoneTop: Color(0xFFFFFFFF),
    sceneStopDoneBottom: Color(0xFFE3EAF0),
    sceneStopDoneSide: Color(0xFFB3C2CF),
    sceneStopDoneRim: Color(0xFF9FB0BF),
    sceneStopCurrentTop: Color(0xFFF8DC90),
    sceneStopCurrentBottom: Color(0xFFD9A13B),
    sceneStopCurrentSide: Color(0xFFA26C1A),
    sceneStopCurrentRim: Color(0xFFFFF3CF),
    sceneStopOnCurrent: Color(0xFF14171C),
    sceneStopUpcomingTop: Color(0xFFF6F9FB),
    sceneStopUpcomingBottom: Color(0xFFDFE7EE),
    sceneStopUpcomingSide: Color(0xFFC4D1DB),
    sceneStopUpcomingRim: Color(0xFFC4D1DB),
    sceneStopOnUpcoming: Color(0xFF30353D),
    sceneStopGraceTop: Color(0xFFEEF7EA),
    sceneStopGraceBottom: Color(0xFFD3E9CF),
    sceneStopGraceSide: Color(0xFFA9C9A5),
    sceneStopGraceRim: Color(0xFF8FB98A),
    sceneStopHighlight: Color(0xFFFFFFFF),
    sceneTravellerCloakTop: Color(0xFF5D72A3),
    sceneTravellerCloakBottom: Color(0xFF2C3754),
    sceneTravellerRim: Color(0xFFD4E3FF),
    sceneTravellerSkinTop: Color(0xFFA5714D),
    sceneTravellerSkinBottom: Color(0xFF6B4229),
    sceneTravellerScarf: Color(0xFFD8694A),
    sceneTravellerScarfShade: Color(0xFFBD5A3D),
    sceneTravellerSatchel: Color(0xFFD29A62),
    sceneTravellerStrap: Color(0xFFB9824F),
    sceneTravellerStaff: Color(0xFF7A5638),
    sceneTravellerBoots: Color(0xFF262B38),
    sceneTravellerInk: Color(0xFF1A1412),
    sceneTravellerHighlight: Color(0xFFFFF1D6),
    sceneDuskSkyTop: Color(0xFF2F3560),
    sceneDuskSkyMid: Color(0xFF6D5F8C),
    sceneDuskSkyHorizon: Color(0xFFE9A877),
    sceneDuskSun: Color(0xD9FFD49A),
    sceneDuskSunDisc: Color(0xFFFFE9C4),
    sceneDuskLand: Color(0xFFB7A6D2),
    sceneDuskScrim: Color(0xD12F3560),
    sceneReader: Color(0xFFFFFFFF),
    sceneReaderGlow: Color(0xBF6FA6DC),
    sceneMarker: Color(0xF5FFFFFF),
    sceneSkyTopClear: Color(0x00BCD8EE),
    sceneSunClear: Color(0x00FFF3CF),
    sceneHazeClear: Color(0x00F4EFE3),
    sceneShadowClear: Color(0x0024402C),
    sceneGlowClear: Color(0x00FFD76E),
    sceneEveningClear: Color(0x00E9A877),
    scenePanelClear: Color(0x00F7F8FA),
    sceneDuskSunClear: Color(0x00FFD49A),
    sceneDuskLandClear: Color(0x00B7A6D2),
    sceneDuskScrimClear: Color(0x002F3560),
    sceneReaderGlowClear: Color(0x006FA6DC),
  );

  static const dark = LumColors(
    bgPage: Color(0xFF161A22),
    bgSurface: Color(0x0BFFFFFF),
    bgSurfaceSunken: Color(0x16FFFFFF),
    bgPrimary: Color(0xFFEEF0F3),
    bgPrimaryContainer: Color(0x16FFFFFF),
    bgSecondary: Color(0x1AFFFFFF),
    bgSecondaryContainer: Color(0x16FFFFFF),
    bgAccentContainer: Color(0x1FE6B85C),
    bgSuccessContainer: Color(0x2486D19C),
    bgDanger: Color(0xFFFFB7B2),
    bgDangerContainer: Color(0x24FFB7B2),
    bgDisabled: Color(0x0FFFFFFF),
    bgInverse: Color(0xFFEEF0F3),
    bgElevated: Color(0xFF2B2F37), // opaque: sheets were see-through
    bgGrouped: Color(0xFF161A22),
    bgGroupedCell: Color(0x0BFFFFFF),
    bgFeature: Color(0x16FFFFFF),
    bgTonal: Color(0x16FFFFFF),
    bgAvatar: Color(0xFFE6B85C),
    bgProjection: Color(0xFF16110A),
    textPrimary: Color(0xFFEEF0F3),
    textSecondary: Color(0xFFC6CAD0),
    textBrand: Color(0xFFEEF0F3),
    textAccent: Color(0xFFEAC578),
    textDanger: Color(0xFFFFB7B2),
    textDisabled: Color(0xFF6B7280),
    textInverse: Color(0xFF111318),
    textOnPrimary: Color(0xFF111318),
    textOnPrimaryContainer: Color(0xFFEEF0F3),
    textOnSecondary: Color(0xFFEEF0F3),
    textOnSecondaryContainer: Color(0xFFEEF0F3),
    textOnAccentContainer: Color(0xFFEAC578),
    textOnSuccessContainer: Color(0xFF86D19C),
    textOnDanger: Color(0xFF1A0505),
    textOnDangerContainer: Color(0xFFFFB7B2),
    textOnLamp: Color(0xFF1E1811),
    textOnFeature: Color(0xFFEEF0F3),
    textOnTonal: Color(0xFFEEF0F3),
    textOnAvatar: Color(0xFF1F1604),
    textOnEveningSky: Color(0xFFEEF0F3),
    textOnProjection: Color(0xFFFEF9F3),
    iconDefault: Color(0xFFEEF0F3),
    iconSecondary: Color(0xFFC6CAD0),
    iconBrand: Color(0xFFEEF0F3),
    iconAccent: Color(0xFFE6B85C),
    iconOnPrimary: Color(0xFF111318),
    iconSuccess: Color(0xFF86D19C),
    iconDanger: Color(0xFFFFB7B2),
    borderSubtle: Color(0x17FFFFFF),
    borderStrong: Color(0x7AFFFFFF),
    borderFocus: Color(0xFFE6B85C),
    borderTonal: Color(0x17FFFFFF),
    statePressed: Color(0x1FFFFFFF),
    stateFocusRing: Color(0xFFE6B85C),
    highlightSun: Color(0x99F2C94C),
    highlightLeaf: Color(0x996FCF97),
    highlightSky: Color(0x9956CCF2),
    highlightRose: Color(0x99EB7FA0),
    highlightLilac: Color(0x99B79CED),
    glassFill: Color(0x0BFFFFFF),
    glassFillOpaque: Color(0xFF1D2129),
    glassStroke: Color(0x17FFFFFF),
    glassEdgeShadow: Color(0x73000000),
    scrimEdge: Color(0xE0161A22),
    scrimPageClear: Color(0x00161A22),
    controlSwitchOn: Color(0xFF86D19C),
    controlSwitchOff: Color(0xFF8B92A0),
    controlSwitchLocked: Color(0xFF5F9A75),
    controlTrackOff: Color(0x7AFFFFFF),
    controlKnob: Color(0xFFFFFFFF),
    lampFlame: Color(0xFFEBB76E),
    lampFlameCore: Color(0xFFFBEAD4),
    lampGlow: Color(0x3DEBB76E),
    lampBody: Color(0xFFAFC1E7),
    lampOil: Color(0xFFFCA990),
    lampUnlit: Color(0xFF6F685F),
    lampMark: Color(0xFFEBB76E),
    qrModule: Color(0xFF2B251E),
    qrTile: Color(0xFFFFFFFF),
    mediaDim: Color(0x59000000),
    mediaOnDim: Color(0xFFFFFFFF),
    liveBg: Color(0xFFC9261B),
    liveOnBg: Color(0xFFFFFFFF),
    liveContainer: Color(0x29FFB7B2),
    glowTint: Color(0xFF3B4A66),
    glowPageTl: Color(0x733B4A66),
    glowPageBr: Color(0x403B4A66),
    buttonPrimaryLip: Color(0xFFAEB4BD),
    buttonGoldTop: Color(0xFFF2CD7A),
    buttonGoldBottom: Color(0xFFE3B153),
    buttonGoldLip: Color(0xFFA3752A),
    buttonOnGold: Color(0xFF1F1604),
    buttonSecondary: Color(0x16FFFFFF),
    buttonSecondaryLip: Color(0x73000000),
    buttonDangerLip: Color(0xFF5E120D),
    tileSelected: Color(0x24E6B85C),
    tileSelectedStroke: Color(0x8CE6B85C),
    tileOnSelected: Color(0xFFEEF0F3),
    tileOnSelectedAccent: Color(0xFFEAC578),
    tileOnSelectedSecondary: Color(0xFFC6CAD0),
    tileStreak: Color(0x29E6B85C),
    tileOnStreak: Color(0xFFEAC578),
    tabActive: Color(0x1AFFFFFF),
    chip: Color(0x16FFFFFF),
    sceneSkyTop: Color(0xFF1C2536),
    sceneSkyMid: Color(0xFF151B27),
    sceneSkyHorizon: Color(0xFF232B3A),
    sceneSun: Color(0x38A9BCE0),
    sceneStar: Color(0xCCFFFFFF),
    sceneCloud: Color(0xFF2C3548),
    sceneCloudShade: Color(0xFF232B3C),
    sceneMountainTop: Color(0xFF253047),
    sceneMountainBottom: Color(0xFF1B2333),
    sceneHillFarTop: Color(0xFF212B3B),
    sceneHillFarBottom: Color(0xFF18202D),
    sceneHaze: Color(0x802A3344),
    sceneHillNearTop: Color(0xFF1D2735),
    sceneHillNearBottom: Color(0xFF141B27),
    sceneHillRim: Color(0xFF3B4A66),
    sceneMeadowTop: Color(0xFF171F2C),
    sceneMeadowBottom: Color(0xFF10151E),
    sceneRoad: Color(0xFF2C3547),
    sceneRoadFar: Color(0xFF1F2738),
    sceneRoadEdge: Color(0xFF0A0D12),
    sceneTreeLight: Color(0xFF26334A),
    sceneTreeDark: Color(0xFF141C29),
    sceneTreeHighlight: Color(0xFF3A4A66),
    sceneTreeTrunk: Color(0xFF0D1118),
    sceneWaterTop: Color(0xFF2A3753),
    sceneWaterBottom: Color(0xFF151C2C),
    sceneWaterRim: Color(0xFF4A5A7A),
    sceneFlowerPink: Color(0xFF3A3F55),
    sceneFlowerGold: Color(0xFF4A4636),
    sceneShadow: Color(0x8C05070A),
    sceneGlow: Color(0xE5F0C060),
    sceneEveningTop: Color(0x4D0B0D14),
    sceneEveningHorizon: Color(0x3D8A5A2A),
    sceneEveningGround: Color(0x4D05070A),
    scenePanel: Color(0xFF121721),
    sceneStopDoneTop: Color(0xFF40372A),
    sceneStopDoneBottom: Color(0xFF2C261D),
    sceneStopDoneSide: Color(0xFF1B1710),
    sceneStopDoneRim: Color(0xFF6E5C3B),
    sceneStopCurrentTop: Color(0xFFF6D68A),
    sceneStopCurrentBottom: Color(0xFFE3B153),
    sceneStopCurrentSide: Color(0xFFA3752A),
    sceneStopCurrentRim: Color(0xFFFFF3CF),
    sceneStopOnCurrent: Color(0xFF1F1604),
    sceneStopUpcomingTop: Color(0xFF2C3547),
    sceneStopUpcomingBottom: Color(0xFF222A39),
    sceneStopUpcomingSide: Color(0xFF131923),
    sceneStopUpcomingRim: Color(0xFF3B4A66),
    sceneStopOnUpcoming: Color(0xFFC6CAD0),
    sceneStopGraceTop: Color(0xFF21362A),
    sceneStopGraceBottom: Color(0xFF192A20),
    sceneStopGraceSide: Color(0xFF0F1A14),
    sceneStopGraceRim: Color(0xFF2F5A3A),
    sceneStopHighlight: Color(0x29FFFFFF),
    sceneTravellerCloakTop: Color(0xFF5A6B96),
    sceneTravellerCloakBottom: Color(0xFF232B42),
    sceneTravellerRim: Color(0xFFF6D68A),
    sceneTravellerSkinTop: Color(0xFF94623F),
    sceneTravellerSkinBottom: Color(0xFF523221),
    sceneTravellerScarf: Color(0xFFC0603F),
    sceneTravellerScarfShade: Color(0xFF94462F),
    sceneTravellerSatchel: Color(0xFFB0814F),
    sceneTravellerStrap: Color(0xFF8A6340),
    sceneTravellerStaff: Color(0xFF6A4A30),
    sceneTravellerBoots: Color(0xFF151922),
    sceneTravellerInk: Color(0xFF100C0A),
    sceneTravellerHighlight: Color(0xFFFFF1D6),
    sceneDuskSkyTop: Color(0x00000000),
    sceneDuskSkyMid: Color(0x00000000),
    sceneDuskSkyHorizon: Color(0x00000000),
    sceneDuskSun: Color(0x00000000),
    sceneDuskSunDisc: Color(0x00000000),
    sceneDuskLand: Color(0x00000000),
    sceneDuskScrim: Color(0x00000000),
    sceneReader: Color(0xFFFFF4DC),
    sceneReaderGlow: Color(0x99FFE2A8),
    sceneMarker: Color(0xF71E2430),
    sceneSkyTopClear: Color(0x001C2536),
    sceneSunClear: Color(0x00A9BCE0),
    sceneHazeClear: Color(0x002A3344),
    sceneShadowClear: Color(0x0005070A),
    sceneGlowClear: Color(0x00E6B85C),
    sceneEveningClear: Color(0x008A5A2A),
    scenePanelClear: Color(0x00121721),
    sceneDuskSunClear: Color(0x00000000),
    sceneDuskLandClear: Color(0x00000000),
    sceneDuskScrimClear: Color(0x00000000),
    sceneReaderGlowClear: Color(0x00FFE2A8),
  );
}

/// Spacing (Figma `spacing/*`).
abstract final class LumSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double barInset = 16;
}

/// Corner radius (Figma `radius/*`).
abstract final class LumRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double full = 999;
}

/// Fixed sizes (Figma `size/*`).
abstract final class LumSize {
  static const double touchTarget = 48;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double screenGutter = 20;
  static const double tabBar = 62;
  static const double glassButton = 48;
  static const double buttonLarge = 52;
  static const double rowMin = 56;
}

/// Durations (Figma `motion/duration/*`). Springs: standard 300/30, bouncy 260/18, reduced 400/40.
abstract final class LumMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration celebration = Duration(milliseconds: 1200);
}

/// Text styles (Figma `Type/*` and `Road/*`). Colour comes from LumColors at the call site.
abstract final class LumText {
  /// `Type/Large Title` Inter 700 34/41
  static const largeTitle = TextStyle(fontFamily: 'Inter', fontSize: 34, height: 1.206, letterSpacing: -0.68, fontWeight: FontWeight.w700);
  /// `Type/Title 1` Inter 700 28/34
  static const title1 = TextStyle(fontFamily: 'Inter', fontSize: 28, height: 1.214, letterSpacing: -0.42, fontWeight: FontWeight.w700);
  /// `Type/Title 2` Inter 600 22/28
  static const title2 = TextStyle(fontFamily: 'Inter', fontSize: 22, height: 1.273, letterSpacing: -0.403, fontWeight: FontWeight.w600);
  /// `Type/Title 3` Inter 600 20/25
  static const title3 = TextStyle(fontFamily: 'Inter', fontSize: 20, height: 1.25, letterSpacing: -0.334, fontWeight: FontWeight.w600);
  /// `Type/Headline` Inter 600 17/22
  static const headline = TextStyle(fontFamily: 'Inter', fontSize: 17, height: 1.294, letterSpacing: -0.218, fontWeight: FontWeight.w600);
  /// `Type/Body` Inter 400 17/22
  static const body = TextStyle(fontFamily: 'Inter', fontSize: 17, height: 1.294, letterSpacing: -0.218, fontWeight: FontWeight.w400);
  /// `Type/Body Emphasized` Inter 600 17/22
  static const bodyEmphasized = TextStyle(fontFamily: 'Inter', fontSize: 17, height: 1.294, letterSpacing: -0.218, fontWeight: FontWeight.w600);
  /// `Type/Callout` Inter 400 16/21
  static const callout = TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.312, letterSpacing: -0.176, fontWeight: FontWeight.w400);
  /// `Type/Subheadline` Inter 400 15/20
  static const subheadline = TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.333, letterSpacing: -0.132, fontWeight: FontWeight.w400);
  /// `Type/Subheadline Emphasized` Inter 600 15/20
  static const subheadlineEmphasized = TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.333, letterSpacing: -0.132, fontWeight: FontWeight.w600);
  /// `Type/Footnote` Inter 400 13/18
  static const footnote = TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.385, letterSpacing: -0.042, fontWeight: FontWeight.w400);
  /// `Type/Footnote Emphasized` Inter 600 13/18
  static const footnoteEmphasized = TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.385, letterSpacing: -0.042, fontWeight: FontWeight.w600);
  /// `Type/Caption` Inter 500 12/16
  static const caption = TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.333, letterSpacing: 0.006, fontWeight: FontWeight.w500);
  /// `Type/Hero Numeral` Bricolage Grotesque 800 56/60
  static const heroNumeral = TextStyle(fontFamily: 'BricolageGrotesque', fontSize: 56, height: 1.071, letterSpacing: -1.68, fontWeight: FontWeight.w800, fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 14)], fontFeatures: [FontFeature.tabularFigures()]);
  /// `Type/Reading/Scripture` Gentium Book Plus 400 20/32
  static const readingScripture = TextStyle(fontFamily: 'GentiumBookPlus', fontSize: 20, height: 1.6, letterSpacing: 0, fontWeight: FontWeight.w400);
  /// `Type/Reading/Lyrics` Gentium Book Plus 400 20/31
  static const readingLyrics = TextStyle(fontFamily: 'GentiumBookPlus', fontSize: 20, height: 1.55, letterSpacing: 0, fontWeight: FontWeight.w400);
  /// `Type/Reading/Lyrics Compact` Gentium Book Plus 400 17/26
  static const readingLyricsCompact = TextStyle(fontFamily: 'GentiumBookPlus', fontSize: 17, height: 1.529, letterSpacing: 0, fontWeight: FontWeight.w400);
  /// `Type/Reading/Verse Quote` Gentium Book Plus 400 18/27
  static const readingVerseQuote = TextStyle(fontFamily: 'GentiumBookPlus', fontSize: 18, height: 1.5, letterSpacing: 0, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic);
  /// `Type/Reading/Verse Number` Inter 600 12/16
  static const readingVerseNumber = TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.333, letterSpacing: 0.006, fontWeight: FontWeight.w600);
  /// `Type/Display/Verse` Gentium Book Plus 400 28/36
  static const displayVerse = TextStyle(fontFamily: 'GentiumBookPlus', fontSize: 28, height: 1.286, letterSpacing: 0, fontWeight: FontWeight.w400);
  /// `Road/Display/Hero 120` Bricolage Grotesque 800 120/108
  static const roadDisplayHero120 = TextStyle(fontFamily: 'BricolageGrotesque', fontSize: 120, height: 0.9, letterSpacing: -3.6, fontWeight: FontWeight.w800, fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 96)], fontFeatures: [FontFeature.tabularFigures()]);
  /// `Road/Display/Large 76` Bricolage Grotesque 800 76/72.2
  static const roadDisplayLarge76 = TextStyle(fontFamily: 'BricolageGrotesque', fontSize: 76, height: 0.95, letterSpacing: -2.28, fontWeight: FontWeight.w800, fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 96)], fontFeatures: [FontFeature.tabularFigures()]);
  /// `Road/Display/Medium 56` Bricolage Grotesque 800 56/56
  static const roadDisplayMedium56 = TextStyle(fontFamily: 'BricolageGrotesque', fontSize: 56, height: 1, letterSpacing: -1.68, fontWeight: FontWeight.w800, fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 14)], fontFeatures: [FontFeature.tabularFigures()]);
  /// `Road/Display/Stat 28` Bricolage Grotesque 800 28/30.8
  static const roadDisplayStat28 = TextStyle(fontFamily: 'BricolageGrotesque', fontSize: 28, height: 1.1, letterSpacing: -0.84, fontWeight: FontWeight.w800, fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 14)], fontFeatures: [FontFeature.tabularFigures()]);
  /// `Road/Title/Large 34` Inter 700 34/37.4
  static const roadTitleLarge34 = TextStyle(fontFamily: 'Inter', fontSize: 34, height: 1.1, letterSpacing: -0.68, fontWeight: FontWeight.w700);
  /// `Road/Title/Small 24` Inter 700 24/27.6
  static const roadTitleSmall24 = TextStyle(fontFamily: 'Inter', fontSize: 24, height: 1.15, letterSpacing: -0.24, fontWeight: FontWeight.w700);
  /// `Road/Label/Caps 11` Inter 600 11/14.3
  static const roadLabelCaps11 = TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.3, letterSpacing: 0.88, fontWeight: FontWeight.w600);
  /// `Road/Reading/Scripture 19` Gentium Book Plus 400 19/31
  static const roadReadingScripture19 = TextStyle(fontFamily: 'GentiumBookPlus', fontSize: 19, height: 1.632, letterSpacing: 0, fontWeight: FontWeight.w400);
}
