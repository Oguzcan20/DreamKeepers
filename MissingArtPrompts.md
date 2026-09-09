# Dreamkeepers — Fehlende Grafiken & Prompt-Texte

Automatisch erzeugte Liste aller Monster, Bosse und Items, die aktuell noch **keine eigene Grafik** in `Assets.xcassets` haben (App zeigt stattdessen ein SF-Symbol-Icon als Platzhalter). Jeder Eintrag hat einen fertigen Prompt-Text zum direkten Einsatz in einem Bildgenerator (Midjourney, DALL·E, Stable Diffusion, ...).

**Dateikonvention beim Einfügen der fertigen Bilder:**
- Monster/Boss: PNG in `Assets.xcassets/Monster_<NameOhneLeerzeichen>.imageset/` ablegen (z. B. `Sunpetal Guardian` → `Monster_SunpetalGuardian`).
- Items: es gibt noch **kein** Namens-Lookup-System für Items (Ausrüstung nutzt bisher nur SF-Symbol-Icons). Die Item-Prompts unten sind trotzdem vorbereitet — sobald die Bilder existieren, muss noch ein kleines `ItemArt`-Lookup analog zu `MonsterArt`/`DreamkeeperArt` gebaut werden, das sagt mir gerne separat Bescheid.

**Dreamkeepers (spielbare Kreaturen): alle 30/30 haben bereits Artwork — hier fehlt nichts.**

**Zusammenfassung:** 80 normale Monster ohne Artwork, 10 Bosse ohne Artwork, 24 Items ohne Artwork (0 von 24 haben aktuell überhaupt ein Kunstwerk-System).

---

## Monster (nach Welt gruppiert)

### Welt 1 — Whispering Meadow

**Sunpetal Guardian** _(Asset: `Monster_SunpetalGuardian`, Rolle: Damage, Seltenheit: Common)_

> Sunpetal Guardian, a Common-tier dream creature. Blooms once at dawn and stands watch over the meadow until dusk. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a quiet, sunlit meadow of tall grass and clover, soft morning light, gentle bokeh. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

### Welt 3 — Crystal Caverns

**Cavern Serpent** _(Asset: `Monster_CavernSerpent`, Rolle: Damage, Seltenheit: Common)_

> Cavern Serpent, a Common-tier dream creature. Coils through the underground tides, patient and impossibly long. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: an underground cavern of frozen, crystalline rock formations, cool blue refracted light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Crystal Wisp** _(Asset: `Monster_CrystalWisp`, Rolle: Damage, Seltenheit: Common)_

> Crystal Wisp, a Common-tier dream creature. Refracts every sound in the cavern into a faint, discordant chime. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: an underground cavern of frozen, crystalline rock formations, cool blue refracted light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

### Welt 4 — Starfall Peaks

**Starfang** _(Asset: `Monster_Starfang`, Rolle: Damage, Seltenheit: Common)_

> Starfang, a Common-tier dream creature. A shard of an old star given teeth, prowling the meteor fields. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Cometpaw** _(Asset: `Monster_Cometpaw`, Rolle: Control, Seltenheit: Uncommon)_

> Cometpaw, an Uncommon-tier dream creature. Leaves a trail of dying light with every leap between floating peaks. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Astralwing** _(Asset: `Monster_Astralwing`, Rolle: Support, Seltenheit: Common)_

> Astralwing, a Common-tier dream creature. Circles the star temple ruins on wings woven from old constellations. Pose/expression: a watchful, alert stance, faint protective glow around it. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Stardustling** _(Asset: `Monster_Stardustling`, Rolle: Healer, Seltenheit: Uncommon)_

> Stardustling, an Uncommon-tier dream creature. Small and glittering, it scatters into motes when startled. Pose/expression: a calm, gentle posture, soft luminous particles or glow drifting from it. A faint magical glow outlines its edges. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Cosmobite** _(Asset: `Monster_Cosmobite`, Rolle: Damage, Seltenheit: Common)_

> Cosmobite, a Common-tier dream creature. Its bite carries a cold, distant chill from beyond the sky. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Nebulaclaw** _(Asset: `Monster_Nebulaclaw`, Rolle: Tank, Seltenheit: Rare)_

> Nebulaclaw, a Rare-tier dream creature. Claws wreathed in drifting cosmic haze, silent as vacuum. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Its most distinctive features glow visibly with inner light. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Starhorn** _(Asset: `Monster_Starhorn`, Rolle: Tank, Seltenheit: Common)_

> Starhorn, a Common-tier dream creature. Charges the crystal spires of Starfall Peaks head-first. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Cometscale** _(Asset: `Monster_Cometscale`, Rolle: Control, Seltenheit: Uncommon)_

> Cometscale, an Uncommon-tier dream creature. Scales that shed light long after the creature has moved on. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

### Welt 5 — The Forgotten Dream

**Moonfang** _(Asset: `Monster_Moonfang`, Rolle: Damage, Seltenheit: Common)_

> Moonfang, a Common-tier dream creature. Wanders the broken buildings, howling at a moon no one else remembers. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Duskhorn** _(Asset: `Monster_Duskhorn`, Rolle: Tank, Seltenheit: Common)_

> Duskhorn, a Common-tier dream creature. Charges out of the dense fog before its silhouette ever resolves. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Nightclaw** _(Asset: `Monster_Nightclaw`, Rolle: Control, Seltenheit: Uncommon)_

> Nightclaw, an Uncommon-tier dream creature. Claws that leave no mark, only the memory of having been cut. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Shadowtail** _(Asset: `Monster_Shadowtail`, Rolle: Damage, Seltenheit: Common)_

> Shadowtail, a Common-tier dream creature. Its tail lags a full second behind the rest of its body. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Eclipsepaw** _(Asset: `Monster_Eclipsepaw`, Rolle: Control, Seltenheit: Rare)_

> Eclipsepaw, a Rare-tier dream creature. Steps between floating ruin-fragments as if they were solid ground. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. Its most distinctive features glow visibly with inner light. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Dreamstalker** _(Asset: `Monster_Dreamstalker`, Rolle: Support, Seltenheit: Uncommon)_

> Dreamstalker, an Uncommon-tier dream creature. Follows dreamers through the fog long after they've woken. Pose/expression: a watchful, alert stance, faint protective glow around it. A faint magical glow outlines its edges. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Moonscale** _(Asset: `Monster_Moonscale`, Rolle: Tank, Seltenheit: Common)_

> Moonscale, a Common-tier dream creature. Scales that dim and brighten with a moon phase all their own. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Gloomfang** _(Asset: `Monster_Gloomfang`, Rolle: Damage, Seltenheit: Uncommon)_

> Gloomfang, an Uncommon-tier dream creature. A last echo of the dream this ruined city used to be. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. A faint magical glow outlines its edges. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

### Welt 6 — Emberheart Wastes

**Cinderfang** _(Asset: `Monster_Cinderfang`, Rolle: Damage, Seltenheit: Common)_

> Cinderfang, a Common-tier dream creature. Prowls the ash fields, jaws glowing faintly with banked heat. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Ashclaw** _(Asset: `Monster_Ashclaw`, Rolle: Tank, Seltenheit: Common)_

> Ashclaw, a Common-tier dream creature. Leaves smoldering prints across the black volcanic rock. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Flamehorn** _(Asset: `Monster_Flamehorn`, Rolle: Tank, Seltenheit: Uncommon)_

> Flamehorn, an Uncommon-tier dream creature. Charges lava lakes head-on without slowing. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. A faint magical glow outlines its edges. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Scorchling** _(Asset: `Monster_Scorchling`, Rolle: Damage, Seltenheit: Common)_

> Scorchling, a Common-tier dream creature. Small, quick, and always a little too close to catching fire. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Embermaw** _(Asset: `Monster_Embermaw`, Rolle: Damage, Seltenheit: Common)_

> Embermaw, a Common-tier dream creature. Its bite carries the heat of a coal that never quite cools. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Blazetail** _(Asset: `Monster_Blazetail`, Rolle: Control, Seltenheit: Uncommon)_

> Blazetail, an Uncommon-tier dream creature. A whip-crack tail that leaves a line of fire in the ash. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Magmabite** _(Asset: `Monster_Magmabite`, Rolle: Damage, Seltenheit: Rare)_

> Magmabite, a Rare-tier dream creature. Bites clean through cooled rock crust in search of the wastes' heat. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Its most distinctive features glow visibly with inner light. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Charhound** _(Asset: `Monster_Charhound`, Rolle: Support, Seltenheit: Common)_

> Charhound, a Common-tier dream creature. Hunts in the choking ash clouds by scent alone. Pose/expression: a watchful, alert stance, faint protective glow around it. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Pyrewing** _(Asset: `Monster_Pyrewing`, Rolle: Control, Seltenheit: Uncommon)_

> Pyrewing, an Uncommon-tier dream creature. Circles the burning ruins on wings of drifting ember. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Inferclaw** _(Asset: `Monster_Inferclaw`, Rolle: Damage, Seltenheit: Common)_

> Inferclaw, a Common-tier dream creature. Claws still hot from the lava lake it just crawled out of. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Coalback** _(Asset: `Monster_Coalback`, Rolle: Tank, Seltenheit: Common)_

> Coalback, a Common-tier dream creature. A ridged spine that glows brighter the angrier it gets. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Searscale** _(Asset: `Monster_Searscale`, Rolle: Damage, Seltenheit: Uncommon)_

> Searscale, an Uncommon-tier dream creature. Scales that scald anything that gets too close. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. A faint magical glow outlines its edges. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Flarefang** _(Asset: `Monster_Flarefang`, Rolle: Damage, Seltenheit: Common)_

> Flarefang, a Common-tier dream creature. A sudden burst of light and teeth from the ash cloud. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Burnpaw** _(Asset: `Monster_Burnpaw`, Rolle: Support, Seltenheit: Common)_

> Burnpaw, a Common-tier dream creature. Leaves scorched pawprints wherever it walks. Pose/expression: a watchful, alert stance, faint protective glow around it. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Ignisprite** _(Asset: `Monster_Ignisprite`, Rolle: Healer, Seltenheit: Rare)_

> Ignisprite, a Rare-tier dream creature. A tiny fire-spirit born from a stray cinder off Ignivar's own flame. Pose/expression: a calm, gentle posture, soft luminous particles or glow drifting from it. Its most distinctive features glow visibly with inner light. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Ashenox** _(Asset: `Monster_Ashenox`, Rolle: Tank, Seltenheit: Uncommon)_

> Ashenox, an Uncommon-tier dream creature. Wears a coat of drifting ash over skin still smoldering beneath. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. A faint magical glow outlines its edges. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

### Welt 7 — Tidal Abyss

**Mistfin** _(Asset: `Monster_Mistfin`, Rolle: Damage, Seltenheit: Common)_

> Mistfin, a Common-tier dream creature. Slips through the coral forest wrapped in a veil of cold mist. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Tideclaw** _(Asset: `Monster_Tideclaw`, Rolle: Tank, Seltenheit: Common)_

> Tideclaw, a Common-tier dream creature. Claws that pull with the force of a rising tide. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Ripplefang** _(Asset: `Monster_Ripplefang`, Rolle: Damage, Seltenheit: Uncommon)_

> Ripplefang, an Uncommon-tier dream creature. Every bite sends a ring of current rippling outward. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. A faint magical glow outlines its edges. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Aquabite** _(Asset: `Monster_Aquabite`, Rolle: Damage, Seltenheit: Common)_

> Aquabite, a Common-tier dream creature. Small and quick, darting between sunken temple pillars. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Wavepup** _(Asset: `Monster_Wavepup`, Rolle: Support, Seltenheit: Common)_

> Wavepup, a Common-tier dream creature. Young and playful, riding the abyss's slow deep currents. Pose/expression: a watchful, alert stance, faint protective glow around it. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Rainscale** _(Asset: `Monster_Rainscale`, Rolle: Healer, Seltenheit: Uncommon)_

> Rainscale, an Uncommon-tier dream creature. Scales that weep a constant, cold trickle of seawater. Pose/expression: a calm, gentle posture, soft luminous particles or glow drifting from it. A faint magical glow outlines its edges. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Deepfin** _(Asset: `Monster_Deepfin`, Rolle: Tank, Seltenheit: Rare)_

> Deepfin, a Rare-tier dream creature. Never surfaces — the trench is the only home it has known. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Its most distinctive features glow visibly with inner light. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Brookling** _(Asset: `Monster_Brookling`, Rolle: Support, Seltenheit: Common)_

> Brookling, a Common-tier dream creature. A trickle of a creature that pools into something larger when threatened. Pose/expression: a watchful, alert stance, faint protective glow around it. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Frostgill** _(Asset: `Monster_Frostgill`, Rolle: Control, Seltenheit: Uncommon)_

> Frostgill, an Uncommon-tier dream creature. Gills that chill the water for a body length in every direction. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Stormfin** _(Asset: `Monster_Stormfin`, Rolle: Damage, Seltenheit: Common)_

> Stormfin, a Common-tier dream creature. Churns the water into a squall wherever it swims. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Pearlmaw** _(Asset: `Monster_Pearlmaw`, Rolle: Damage, Seltenheit: Common)_

> Pearlmaw, a Common-tier dream creature. Its jaw glints with a lifetime of swallowed pearls. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Splashpaw** _(Asset: `Monster_Splashpaw`, Rolle: Control, Seltenheit: Uncommon)_

> Splashpaw, an Uncommon-tier dream creature. Bounds along the sunken temple floor in bursts of current. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Drownscale** _(Asset: `Monster_Drownscale`, Rolle: Tank, Seltenheit: Rare)_

> Drownscale, a Rare-tier dream creature. Legend says it once pulled an entire temple beneath the waves. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Its most distinctive features glow visibly with inner light. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Riverfang** _(Asset: `Monster_Riverfang`, Rolle: Damage, Seltenheit: Common)_

> Riverfang, a Common-tier dream creature. Older than the abyss itself, or so the coral forest tells it. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Mistcrawler** _(Asset: `Monster_Mistcrawler`, Rolle: Support, Seltenheit: Common)_

> Mistcrawler, a Common-tier dream creature. Crawls along the trench floor where no light has ever reached. Pose/expression: a watchful, alert stance, faint protective glow around it. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Abyssfin** _(Asset: `Monster_Abyssfin`, Rolle: Damage, Seltenheit: Uncommon)_

> Abyssfin, an Uncommon-tier dream creature. The deepest-dwelling of Thalassor's countless subjects. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. A faint magical glow outlines its edges. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

### Welt 8 — Eternal Bloom

**Thornpaw** _(Asset: `Monster_Thornpaw`, Rolle: Damage, Seltenheit: Common)_

> Thornpaw, a Common-tier dream creature. Pads silently through root tunnels wider than any road. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Mossfang** _(Asset: `Monster_Mossfang`, Rolle: Tank, Seltenheit: Common)_

> Mossfang, a Common-tier dream creature. So thickly covered in moss it looks like part of the jungle floor. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Leafling** _(Asset: `Monster_Leafling`, Rolle: Support, Seltenheit: Common)_

> Leafling, a Common-tier dream creature. Small and quick, camouflaged among the oversized canopy. Pose/expression: a watchful, alert stance, faint protective glow around it. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Rootclaw** _(Asset: `Monster_Rootclaw`, Rolle: Damage, Seltenheit: Uncommon)_

> Rootclaw, an Uncommon-tier dream creature. Claws grown from a root that never stopped reaching. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. A faint magical glow outlines its edges. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Vinebeast** _(Asset: `Monster_Vinebeast`, Rolle: Tank, Seltenheit: Uncommon)_

> Vinebeast, an Uncommon-tier dream creature. Trails living vine behind it as it moves through the undergrowth. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. A faint magical glow outlines its edges. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Bloomtail** _(Asset: `Monster_Bloomtail`, Rolle: Control, Seltenheit: Common)_

> Bloomtail, a Common-tier dream creature. A flowering tail that opens only when it senses a threat. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Petalhorn** _(Asset: `Monster_Petalhorn`, Rolle: Tank, Seltenheit: Common)_

> Petalhorn, a Common-tier dream creature. Charges beneath an oversized, brilliantly colored bloom. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Barkhide** _(Asset: `Monster_Barkhide`, Rolle: Tank, Seltenheit: Rare)_

> Barkhide, a Rare-tier dream creature. Skin as tough and gnarled as the jungle's oldest trees. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Its most distinctive features glow visibly with inner light. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Sporeling** _(Asset: `Monster_Sporeling`, Rolle: Healer, Seltenheit: Uncommon)_

> Sporeling, an Uncommon-tier dream creature. Releases a faint cloud of spores whenever it's startled. Pose/expression: a calm, gentle posture, soft luminous particles or glow drifting from it. A faint magical glow outlines its edges. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Wildthorn** _(Asset: `Monster_Wildthorn`, Rolle: Damage, Seltenheit: Common)_

> Wildthorn, a Common-tier dream creature. A tangle of thorn and muscle native only to Eternal Bloom. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Fernfang** _(Asset: `Monster_Fernfang`, Rolle: Damage, Seltenheit: Common)_

> Fernfang, a Common-tier dream creature. Bites through the thick canopy vines with practiced ease. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Brambleback** _(Asset: `Monster_Brambleback`, Rolle: Tank, Seltenheit: Uncommon)_

> Brambleback, an Uncommon-tier dream creature. A spine of interlocking brambles no predator wants to test. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. A faint magical glow outlines its edges. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Rootmaw** _(Asset: `Monster_Rootmaw`, Rolle: Damage, Seltenheit: Rare)_

> Rootmaw, a Rare-tier dream creature. Waits beneath the tunnel floor for something to walk overhead. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Its most distinctive features glow visibly with inner light. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Seedling Beast** _(Asset: `Monster_SeedlingBeast`, Rolle: Support, Seltenheit: Common)_

> Seedling Beast, a Common-tier dream creature. Young, but already larger than most fully grown Bloom creatures. Pose/expression: a watchful, alert stance, faint protective glow around it. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Ivyclaw** _(Asset: `Monster_Ivyclaw`, Rolle: Control, Seltenheit: Uncommon)_

> Ivyclaw, an Uncommon-tier dream creature. Ivy grows over its claws between meals, then sheds when it hunts. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Thornbloom** _(Asset: `Monster_Thornbloom`, Rolle: Damage, Seltenheit: Uncommon)_

> Thornbloom, an Uncommon-tier dream creature. The jungle's oldest bloom given claws, close kin to Verdantor. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. A faint magical glow outlines its edges. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

### Welt 9 — Realm of Eclipse

**Nightshade** _(Asset: `Monster_Nightshade`, Rolle: Damage, Seltenheit: Common)_

> Nightshade, a Common-tier dream creature. Grows only where Noctyra's permanent eclipse falls darkest. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Environment: a land in permanent eclipse beneath a vast watching moon, near-black with thin silver rim light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Lunawing** _(Asset: `Monster_Lunawing`, Rolle: Control, Seltenheit: Uncommon)_

> Lunawing, an Uncommon-tier dream creature. Circles the watching moon on wings that never cast a shadow. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: a land in permanent eclipse beneath a vast watching moon, near-black with thin silver rim light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Darkpelt** _(Asset: `Monster_Darkpelt`, Rolle: Tank, Seltenheit: Common)_

> Darkpelt, a Common-tier dream creature. A coat so black it swallows the eclipse's faint light entirely. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: a land in permanent eclipse beneath a vast watching moon, near-black with thin silver rim light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Crescentclaw** _(Asset: `Monster_Crescentclaw`, Rolle: Damage, Seltenheit: Rare)_

> Crescentclaw, a Rare-tier dream creature. Claws curved like the sliver of moon this realm never quite sees. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Its most distinctive features glow visibly with inner light. Environment: a land in permanent eclipse beneath a vast watching moon, near-black with thin silver rim light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Voidpaw** _(Asset: `Monster_Voidpaw`, Rolle: Control, Seltenheit: Uncommon)_

> Voidpaw, an Uncommon-tier dream creature. Steps leave no print — the eclipse realm forgets it was ever there. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. A faint magical glow outlines its edges. Environment: a land in permanent eclipse beneath a vast watching moon, near-black with thin silver rim light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Duskscale** _(Asset: `Monster_Duskscale`, Rolle: Tank, Seltenheit: Common)_

> Duskscale, a Common-tier dream creature. Scales caught permanently between day and night. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Environment: a land in permanent eclipse beneath a vast watching moon, near-black with thin silver rim light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Nightmare Beast** _(Asset: `Monster_NightmareBeast`, Rolle: Damage, Seltenheit: Rare)_

> Nightmare Beast, a Rare-tier dream creature. One of Noctyra's own court, given form from the realm's endless dark. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Its most distinctive features glow visibly with inner light. Environment: a land in permanent eclipse beneath a vast watching moon, near-black with thin silver rim light. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

### Welt 10 — Celestial Dream

**Galaxipaw** _(Asset: `Monster_Galaxipaw`, Rolle: Damage, Seltenheit: Uncommon)_

> Galaxipaw, an Uncommon-tier dream creature. Each pawprint briefly holds a swirl of tiny stars. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. A faint magical glow outlines its edges. Environment: cosmic islands and starlit temples at the center of the Dream realm, golden starlight and nebula colors. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Meteorfang** _(Asset: `Monster_Meteorfang`, Rolle: Damage, Seltenheit: Rare)_

> Meteorfang, a Rare-tier dream creature. Fell to the cosmic islands still burning at the edges. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Its most distinctive features glow visibly with inner light. Environment: cosmic islands and starlit temples at the center of the Dream realm, golden starlight and nebula colors. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Celestling** _(Asset: `Monster_Celestling`, Rolle: Support, Seltenheit: Uncommon)_

> Celestling, an Uncommon-tier dream creature. Small, but drawn from the same light as Elyndor itself. Pose/expression: a watchful, alert stance, faint protective glow around it. A faint magical glow outlines its edges. Environment: cosmic islands and starlit temples at the center of the Dream realm, golden starlight and nebula colors. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Voidstar** _(Asset: `Monster_Voidstar`, Rolle: Control, Seltenheit: Rare)_

> Voidstar, a Rare-tier dream creature. A star gone dark, still pulling everything nearby toward it. Pose/expression: an eerie, unsettling posture with an unnatural stillness or hypnotic gaze. Its most distinctive features glow visibly with inner light. Environment: cosmic islands and starlit temples at the center of the Dream realm, golden starlight and nebula colors. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Nebulabeast** _(Asset: `Monster_Nebulabeast`, Rolle: Tank, Seltenheit: Uncommon)_

> Nebulabeast, an Uncommon-tier dream creature. Drifts between the starlit temples wrapped in cosmic haze. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. A faint magical glow outlines its edges. Environment: cosmic islands and starlit temples at the center of the Dream realm, golden starlight and nebula colors. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Starlight Claw** _(Asset: `Monster_StarlightClaw`, Rolle: Damage, Seltenheit: Rare)_

> Starlight Claw, a Rare-tier dream creature. Claws that glow with borrowed light from a galaxy long gone. Pose/expression: an aggressive, coiled stance with sharp fangs/claws bared, ready to strike. Its most distinctive features glow visibly with inner light. Environment: cosmic islands and starlit temples at the center of the Dream realm, golden starlight and nebula colors. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

---

## Bosse (alle 10 fehlen)

**The Unraveling** _(Welt 1 — Whispering Meadow, Asset: `Monster_TheUnraveling`)_

> The Unraveling, a Legendary-tier dream creature. Once the meadow's oldest bloom, now unraveling into thorn and flame with every dream it consumes. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: a quiet, sunlit meadow of tall grass and clover, soft morning light, gentle bokeh. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Nightmare Warden** _(Welt 2 — Moonlit Forest, Asset: `Monster_NightmareWarden`)_

> Nightmare Warden, a Legendary-tier dream creature. Keeper of the forest's deepest gloom, it grows more furious the closer it comes to falling. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: a dark, moonlit forest with glowing dream-flora, cold blue-violet light, fog between the trees. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Crystal Sentinel** _(Welt 3 — Crystal Caverns, Asset: `Monster_CrystalSentinel`)_

> Crystal Sentinel, a Legendary-tier dream creature. A living crystal grown around a dream too heavy to wake from, shielded on every side. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: an underground cavern of frozen, crystalline rock formations, cool blue refracted light. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Aetherion, the Fallen Star** _(Welt 4 — Starfall Peaks, Asset: `Monster_AetheriontheFallenStar`)_

> Aetherion, the Fallen Star, a Legendary-tier dream creature. A star that fell from the heavens eons ago, still burning with the light of its old sky. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: floating mountain peaks and a meteor field around an ancient star temple, deep night sky, streaking starlight. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Morvane, Dream Eater** _(Welt 5 — The Forgotten Dream, Asset: `Monster_MorvaneDreamEater`)_

> Morvane, Dream Eater, a Legendary-tier dream creature. An ancient thing that feeds on forgotten dreams, growing fatter with every one it swallows. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: broken buildings and floating ruins lost in a dense, surreal fog, muted grey-violet light. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Ignivar, Lord of Ash** _(Welt 6 — Emberheart Wastes, Asset: `Monster_IgnivarLordofAsh`)_

> Ignivar, Lord of Ash, a Legendary-tier dream creature. A titan of fire that slept beneath the wastes for a thousand years, now awake and furious. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: volcanic wastes with lava lakes and a sky choked with ash, hot orange-red glow. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Thalassor, Abyssal King** _(Welt 7 — Tidal Abyss, Asset: `Monster_ThalassorAbyssalKing`)_

> Thalassor, Abyssal King, a Legendary-tier dream creature. Ruler of the deepest trench in the Tidal Abyss, its court are things that never see the surface. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: a sunken temple and coral forest deep in a lightless ocean trench, cold teal bioluminescence. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Verdantor, Ancient Root** _(Welt 8 — Eternal Bloom, Asset: `Monster_VerdantorAncientRoot`)_

> Verdantor, Ancient Root, a Legendary-tier dream creature. A root older than the forest itself, slumbering beneath Eternal Bloom since before memory. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: a colossal magical jungle of root tunnels and oversized glowing flora, rich green light. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Noctyra, Queen of Night** _(Welt 9 — Realm of Eclipse, Asset: `Monster_NoctyraQueenofNight`)_

> Noctyra, Queen of Night, a Legendary-tier dream creature. Sovereign of the permanent eclipse, she rules the realm equally in shadow and stolen light. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: a land in permanent eclipse beneath a vast watching moon, near-black with thin silver rim light. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

**Elyndor, The Dream Sovereign** _(Welt 10 — Celestial Dream, Asset: `Monster_ElyndorTheDreamSovereign`)_

> Elyndor, The Dream Sovereign, a Legendary-tier dream creature. Ruler of the highest dream, and the last, greatest guardian the Dreamkeepers must face. Pose/expression: a heavily-built, armored stance, planted firmly, radiating sturdy defiance. Radiates a powerful, unmistakable aura of light/energy — clearly the most powerful creature in its domain. Environment: cosmic islands and starlit temples at the center of the Dream realm, golden starlight and nebula colors. This is a world-ending boss creature — render it noticeably larger and more imposing than a regular monster, in a powerful dynamic pose, with strong dramatic rim lighting to emphasize its scale. Semi-realistic digital painting, dreamlike dark-fantasy creature portrait, square 1:1 composition, single creature centered and fully visible, dramatic atmospheric lighting matching the scene, shallow depth of field, no text, no watermark, no UI elements. Matches the existing in-game art (Monster_MeadowSprite.png, Monster_GloomHound.png) in rendering quality and mood.

---

## Items / Ausrüstung (alle 24 fehlen — es gibt noch kein Item-Art-System)

### Weapon

**Ember Dagger**

> Ember Dagger (Weapon), a short blade forged from cooling volcanic glass, its edge still faintly glowing orange like a dying ember. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Bramble Wand**

> Bramble Wand (Weapon), a gnarled wooden wand grown rather than carved, thorny living bramble wrapped around a smooth core, small green buds along its length. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Tidecaller Blade**

> Tidecaller Blade (Weapon), a curved blade that looks poured from seawater and frozen mid-wave, pale teal and translucent with a faint current swirling inside it. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Lunar Piercer**

> Lunar Piercer (Weapon), a slender, curved silver spike-blade that seems carved from moonlight, faint pale glow along its edge. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Astral Spear**

> Astral Spear (Weapon), a long, elegant spear with a translucent starlit tip, tiny points of light drifting along its shaft. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Crystal Cleaver**

> Crystal Cleaver (Weapon), a broad-bladed cleaver grown from faceted blue crystal, refracting light in sharp internal fractures. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

### Charm

**Moonstone Charm**

> Moonstone Charm (Charm), a small pendant set with a pale, glowing moonstone, hung on a simple cord. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Warding Sigil**

> Warding Sigil (Charm), a carved stone or bone talisman etched with a protective rune, glowing faintly along the engraved lines. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Dream Locket**

> Dream Locket (Charm), a delicate old locket with a soft inner glow, as if a small dream were captured behind its clasp. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Ember Talisman**

> Ember Talisman (Charm), a small carved talisman with a glowing coal-red core, warm light pulsing faintly at its center. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Tideheart Pendant**

> Tideheart Pendant (Charm), a teardrop pendant holding a swirl of captured seawater, gently sloshing behind clear crystal. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Bloomseed Charm**

> Bloomseed Charm (Charm), a tiny woven pod charm with a single luminous seed visible inside, faint green glow. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

### Cloak

**Woven Nightcloak**

> Woven Nightcloak (Cloak), a dark, star-flecked cloak that seems to drink in the light around it, hem trailing like smoke. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Starlit Mantle**

> Starlit Mantle (Cloak), a pale, flowing mantle scattered with tiny points of starlight that drift slowly across the fabric. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Bark Shroud**

> Bark Shroud (Cloak), a rough cloak made of living bark and moss, textured like tree skin, with small leaves growing along the collar. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Emberweave Cloak**

> Emberweave Cloak (Cloak), a cloak woven from threads that glow like dying embers, faint smoke curling from the hem. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Tidewoven Cape**

> Tidewoven Cape (Cloak), a flowing cape that ripples like water even when still, pale teal with a faint current pattern. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Crystalline Veil**

> Crystalline Veil (Cloak), a sheer, faceted cloak that catches and scatters light like cut crystal, cold blue-white sheen. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

### Ring

**Whisper Ring**

> Whisper Ring (Ring), a thin, dark ring engraved with tiny spiraling runes, barely visible unless caught in the light. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Bloomband**

> Bloomband (Ring), a delicate ring shaped like a small vine, with a single tiny flower blooming from its band. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Rift Loop**

> Rift Loop (Ring), a ring with a fractured, crystalline band as if a small tear in space were caught and cooled into a circle. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Emberband**

> Emberband (Ring), a thin metal ring with a single glowing ember-orange gem set flush into the band. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Tideloop Ring**

> Tideloop Ring (Ring), a ring shaped like a small breaking wave, cast in pale sea-glass blue. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.

**Duskbrand Ring**

> Duskbrand Ring (Ring), a dark iron ring branded with a faint crescent-moon mark that glows a dim violet. Stylized fantasy RPG item icon, single object centered on a plain dark background, semi-realistic painterly render with soft rim lighting, 1:1 square composition, no text, no watermark, no UI frame (rarity-colored frames/glows are added separately in-app). Matches the painterly rendering quality of the game's creature art.
