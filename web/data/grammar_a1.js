/* DeepQ Grammatikbuch — A1 (module 13). Validated reference content written for DeepQ.
 * lesson: { id, de, fr, en, intro{fr,en} (small HTML), tables[{head[], rows[][]}], examples[[de,fr,en]],
 *           ex[{q (German, ___ = gap), opts[], a (index), why{fr,en}}] }  */
window.DQ_DATA = window.DQ_DATA || {};
DQ_DATA.grammar = [
  { id: "g01", de: "Personalpronomen, sein und haben", fr: "Pronoms personnels, « sein » et « haben »", en: "Personal pronouns, sein and haben",
    intro: {
      fr: "<p>Les pronoms sujets : <b>ich, du, er/sie/es, wir, ihr, sie/Sie</b>. <b>du</b> s’emploie avec la famille, les amis et les enfants ; <b>Sie</b> (avec majuscule) est la forme de politesse, singulier ou pluriel.</p><p><b>sein</b> (être) et <b>haben</b> (avoir) sont irréguliers : apprends-les par cœur.</p>",
      en: "<p>Subject pronouns: <b>ich, du, er/sie/es, wir, ihr, sie/Sie</b>. Use <b>du</b> with family, friends and children; <b>Sie</b> (capital S) is the polite form, singular or plural.</p><p><b>sein</b> (to be) and <b>haben</b> (to have) are irregular: learn them by heart.</p>" },
    tables: [{ head: ["", "sein", "haben"], rows: [["ich", "bin", "habe"], ["du", "bist", "hast"], ["er/sie/es", "ist", "hat"], ["wir", "sind", "haben"], ["ihr", "seid", "habt"], ["sie/Sie", "sind", "haben"]] }],
    examples: [["Ich bin Lehrerin.", "Je suis enseignante.", "I’m a teacher."], ["Hast du einen Bruder?", "As-tu un frère ?", "Do you have a brother?"], ["Sind Sie Herr Weber?", "Êtes-vous Monsieur Weber ?", "Are you Mr Weber?"]],
    ex: [
      { q: "Wir ___ müde.", opts: ["sind", "seid", "ist"], a: 0, why: { fr: "wir → sind.", en: "wir → sind." } },
      { q: "___ du Zeit?", opts: ["Hast", "Hat", "Habt"], a: 0, why: { fr: "du → hast.", en: "du → hast." } },
      { q: "Er ___ aus Italien.", opts: ["bin", "ist", "bist"], a: 1, why: { fr: "er → ist.", en: "er → ist." } },
      { q: "Ihr ___ zwei Kinder.", opts: ["haben", "hat", "habt"], a: 2, why: { fr: "ihr → habt.", en: "ihr → habt." } },
      { q: "Frau Weber, ___ Sie Hunger?", opts: ["haben", "hast", "habt"], a: 0, why: { fr: "Sie (politesse) → haben, comme le pluriel.", en: "Polite Sie → haben, like the plural." } },
    ] },

  { id: "g02", de: "Präsens: regelmäßige Verben", fr: "Le présent des verbes réguliers", en: "Present tense of regular verbs",
    intro: {
      fr: "<p>On enlève <b>-en</b> de l’infinitif (wohn<b>en</b> → <b>wohn-</b>) et on ajoute les terminaisons <b>-e, -st, -t, -en, -t, -en</b>.</p><p>Si le radical finit par <b>-t/-d</b> (arbeiten, finden), on ajoute un <b>e</b> : du arbeit<b>e</b>st, er arbeit<b>e</b>t. Après <b>-s/-ß/-z</b>, du prend seulement <b>-t</b> : du heißt, du tanzt.</p>",
      en: "<p>Drop <b>-en</b> from the infinitive (wohn<b>en</b> → <b>wohn-</b>) and add <b>-e, -st, -t, -en, -t, -en</b>.</p><p>If the stem ends in <b>-t/-d</b> (arbeiten, finden), add an <b>e</b>: du arbeit<b>e</b>st, er arbeit<b>e</b>t. After <b>-s/-ß/-z</b>, du only takes <b>-t</b>: du heißt, du tanzt.</p>" },
    tables: [{ head: ["", "wohnen", "arbeiten", "heißen"], rows: [["ich", "wohne", "arbeite", "heiße"], ["du", "wohnst", "arbeitest", "heißt"], ["er/sie/es", "wohnt", "arbeitet", "heißt"], ["wir", "wohnen", "arbeiten", "heißen"], ["ihr", "wohnt", "arbeitet", "heißt"], ["sie/Sie", "wohnen", "arbeiten", "heißen"]] }],
    examples: [["Ich wohne in Hamburg.", "J’habite à Hambourg.", "I live in Hamburg."], ["Arbeitest du heute?", "Tu travailles aujourd’hui ?", "Are you working today?"], ["Wie heißt du?", "Comment t’appelles-tu ?", "What’s your name?"]],
    ex: [
      { q: "Du ___ (lernen) Deutsch.", opts: ["lernst", "lernt", "lerne"], a: 0, why: { fr: "du → -st.", en: "du → -st." } },
      { q: "Sie (elle) ___ (arbeiten) in Bonn.", opts: ["arbeit", "arbeitet", "arbeitt"], a: 1, why: { fr: "Radical en -t : er/sie arbeit-e-t.", en: "Stem in -t: er/sie arbeit-e-t." } },
      { q: "Wie ___ (heißen) du?", opts: ["heißst", "heißt", "heißest"], a: 1, why: { fr: "Radical en -ß : du heißt.", en: "Stem in -ß: du heißt." } },
      { q: "Wir ___ (spielen) Fußball.", opts: ["spielen", "spielt", "spielst"], a: 0, why: { fr: "wir → -en.", en: "wir → -en." } },
      { q: "Ihr ___ (kochen) sehr gut.", opts: ["kochen", "kocht", "kochst"], a: 1, why: { fr: "ihr → -t.", en: "ihr → -t." } },
    ] },

  { id: "g03", de: "Artikel im Nominativ", fr: "Les articles au nominatif", en: "Articles in the nominative",
    intro: {
      fr: "<p>Chaque nom a un genre : <b>der</b> (masculin), <b>die</b> (féminin), <b>das</b> (neutre). Au pluriel : toujours <b>die</b>. Apprends toujours le nom avec son article !</p><p>Article indéfini : <b>ein</b> (der/das), <b>eine</b> (die). Pas d’article indéfini au pluriel.</p><p>Astuces : les noms en <b>-ung, -heit, -keit, -e</b> sont souvent féminins ; en <b>-chen, -lein</b> toujours neutres.</p>",
      en: "<p>Every noun has a gender: <b>der</b> (masculine), <b>die</b> (feminine), <b>das</b> (neuter). Plural: always <b>die</b>. Always learn a noun with its article!</p><p>Indefinite article: <b>ein</b> (der/das), <b>eine</b> (die). No indefinite article in the plural.</p><p>Tips: nouns ending in <b>-ung, -heit, -keit, -e</b> are often feminine; <b>-chen, -lein</b> are always neuter.</p>" },
    tables: [{ head: ["", "maskulin", "feminin", "neutral", "Plural"], rows: [["bestimmt", "der Tisch", "die Lampe", "das Buch", "die Bücher"], ["unbestimmt", "ein Tisch", "eine Lampe", "ein Buch", "– Bücher"]] }],
    examples: [["Das ist ein Stuhl. Der Stuhl ist neu.", "C’est une chaise. La chaise est neuve.", "That’s a chair. The chair is new."], ["Die Wohnung ist schön.", "L’appartement est beau.", "The flat is beautiful."]],
    ex: [
      { q: "___ Brötchen ist frisch.", opts: ["Der", "Die", "Das"], a: 2, why: { fr: "-chen → toujours neutre : das Brötchen.", en: "-chen → always neuter: das Brötchen." } },
      { q: "___ Zeitung liegt auf dem Tisch.", opts: ["Der", "Die", "Das"], a: 1, why: { fr: "-ung → féminin : die Zeitung.", en: "-ung → feminine: die Zeitung." } },
      { q: "Das ist ___ Lampe.", opts: ["ein", "eine", "einen"], a: 1, why: { fr: "die Lampe → eine Lampe.", en: "die Lampe → eine Lampe." } },
      { q: "Das ist ___ Kind.", opts: ["ein", "eine", "der"], a: 0, why: { fr: "das Kind → ein Kind.", en: "das Kind → ein Kind." } },
      { q: "___ Kinder spielen im Park.", opts: ["Der", "Das", "Die"], a: 2, why: { fr: "Pluriel → die.", en: "Plural → die." } },
    ] },

  { id: "g04", de: "Plural der Nomen", fr: "Le pluriel des noms", en: "Plural of nouns",
    intro: {
      fr: "<p>Le pluriel allemand a plusieurs formes ; apprends-le avec le mot. Les plus fréquentes : <b>-e</b> (Tag → Tage), <b>-¨e</b> (Stuhl → Stühle), <b>-er/-¨er</b> (Kind → Kinder, Buch → Bücher), <b>-(e)n</b> (Frau → Frauen, Lampe → Lampen), <b>-s</b> (Auto → Autos) et <b>sans changement</b> (Lehrer → Lehrer, Brötchen → Brötchen).</p><p>Les féminins en <b>-in</b> font <b>-innen</b> : Freundin → Freundinnen.</p>",
      en: "<p>German plurals take several forms; learn them with the word. The most common: <b>-e</b> (Tag → Tage), <b>-¨e</b> (Stuhl → Stühle), <b>-er/-¨er</b> (Kind → Kinder, Buch → Bücher), <b>-(e)n</b> (Frau → Frauen, Lampe → Lampen), <b>-s</b> (Auto → Autos) and <b>no change</b> (Lehrer → Lehrer, Brötchen → Brötchen).</p><p>Feminine nouns in <b>-in</b> take <b>-innen</b>: Freundin → Freundinnen.</p>" },
    tables: [{ head: ["Endung", "Singular", "Plural"], rows: [["-e", "der Tag", "die Tage"], ["-¨e", "der Stuhl", "die Stühle"], ["-er / -¨er", "das Buch", "die Bücher"], ["-(e)n", "die Lampe", "die Lampen"], ["-s", "das Auto", "die Autos"], ["–", "das Brötchen", "die Brötchen"]] }],
    examples: [["Zwei Brötchen, bitte.", "Deux petits pains, s’il vous plaît.", "Two rolls, please."], ["Die Kinder spielen.", "Les enfants jouent.", "The children are playing."]],
    ex: [
      { q: "das Brötchen → zwei ___", opts: ["Brötchens", "Brötchen", "Brötchene"], a: 1, why: { fr: "-chen ne change pas au pluriel.", en: "-chen doesn’t change in the plural." } },
      { q: "die Freundin → die ___", opts: ["Freundinen", "Freundinnen", "Freundins"], a: 1, why: { fr: "-in → -innen.", en: "-in → -innen." } },
      { q: "das Buch → die ___", opts: ["Buchs", "Büche", "Bücher"], a: 2, why: { fr: "Buch → Bücher (-¨er).", en: "Buch → Bücher (-¨er)." } },
      { q: "das Auto → die ___", opts: ["Autos", "Auten", "Autoe"], a: 0, why: { fr: "Mots en -o → -s.", en: "Words in -o → -s." } },
      { q: "der Apfel → die ___", opts: ["Apfeln", "Äpfel", "Äpfels"], a: 1, why: { fr: "Apfel → Äpfel (umlaut, sans terminaison).", en: "Apfel → Äpfel (umlaut, no ending)." } },
    ] },

  { id: "g05", de: "Der Akkusativ", fr: "L’accusatif", en: "The accusative",
    intro: {
      fr: "<p>Le complément d’objet direct est à l’<b>accusatif</b> (après <i>haben, kaufen, brauchen, möchten, essen…</i>). Seul le <b>masculin</b> change : <b>der → den</b>, <b>ein → einen</b>, <b>kein → keinen</b>. Féminin, neutre et pluriel restent comme au nominatif.</p><p>C’est pourquoi on dit « ein Brot » (neutre) mais « einen Kaffee » (masculin).</p>",
      en: "<p>The direct object is in the <b>accusative</b> (after <i>haben, kaufen, brauchen, möchten, essen…</i>). Only the <b>masculine</b> changes: <b>der → den</b>, <b>ein → einen</b>, <b>kein → keinen</b>. Feminine, neuter and plural stay as in the nominative.</p><p>That’s why you say “ein Brot” (neuter) but “einen Kaffee” (masculine).</p>" },
    tables: [{ head: ["", "maskulin", "feminin", "neutral", "Plural"], rows: [["Nominativ", "der / ein", "die / eine", "das / ein", "die / –"], ["Akkusativ", "<b>den / einen</b>", "die / eine", "das / ein", "die / –"]] }],
    examples: [["Ich kaufe einen Kuchen.", "J’achète un gâteau.", "I’m buying a cake."], ["Ich hätte gern ein Brot.", "J’aimerais un pain.", "I’d like a loaf of bread."], ["Er braucht den Schlüssel.", "Il a besoin de la clé.", "He needs the key."]],
    ex: [
      { q: "Ich möchte ___ Kaffee.", opts: ["ein", "einen", "eine"], a: 1, why: { fr: "der Kaffee → Akk. einen Kaffee.", en: "der Kaffee → acc. einen Kaffee." } },
      { q: "Ich hätte gern ___ Weißbrot.", opts: ["einen", "ein", "eine"], a: 1, why: { fr: "das Brot est neutre : ein Weißbrot (pas « einen »).", en: "das Brot is neuter: ein Weißbrot (not “einen”)." } },
      { q: "Wir kaufen ___ Banane.", opts: ["einen", "eine", "ein"], a: 1, why: { fr: "die Banane → eine Banane.", en: "die Banane → eine Banane." } },
      { q: "Siehst du ___ Bus?", opts: ["der", "den", "dem"], a: 1, why: { fr: "der Bus → Akk. den Bus.", en: "der Bus → acc. den Bus." } },
      { q: "Sie hat ___ Hund.", opts: ["ein", "einen", "einem"], a: 1, why: { fr: "der Hund → einen Hund.", en: "der Hund → einen Hund." } },
    ] },

  { id: "g06", de: "Negation: nicht und kein", fr: "La négation : « nicht » et « kein »", en: "Negation: nicht and kein",
    intro: {
      fr: "<p><b>kein</b> nie un nom avec article indéfini ou sans article : <i>Ich habe ein Auto → Ich habe <b>kein</b> Auto.</i> Il se décline comme <b>ein</b> (keinen au masculin accusatif, keine au pluriel).</p><p><b>nicht</b> nie le reste : un verbe, un adjectif, un nom avec article défini : <i>Ich arbeite <b>nicht</b>. Das ist <b>nicht</b> teuer.</i></p>",
      en: "<p><b>kein</b> negates a noun with an indefinite article or no article: <i>Ich habe ein Auto → Ich habe <b>kein</b> Auto.</i> It changes like <b>ein</b> (keinen in the masculine accusative, keine in the plural).</p><p><b>nicht</b> negates everything else: a verb, an adjective, a noun with a definite article: <i>Ich arbeite <b>nicht</b>. Das ist <b>nicht</b> teuer.</i></p>" },
    tables: [{ head: ["positiv", "negativ"], rows: [["Ich habe einen Bruder.", "Ich habe <b>keinen</b> Bruder."], ["Ich trinke Kaffee.", "Ich trinke <b>keinen</b> Kaffee."], ["Ich komme heute.", "Ich komme heute <b>nicht</b>."], ["Das ist teuer.", "Das ist <b>nicht</b> teuer."]] }],
    examples: [["Ich habe keine Zeit.", "Je n’ai pas le temps.", "I don’t have time."], ["Er wohnt nicht in Berlin.", "Il n’habite pas à Berlin.", "He doesn’t live in Berlin."]],
    ex: [
      { q: "Ich habe ___ Hunger.", opts: ["nicht", "kein", "keinen"], a: 2, why: { fr: "der Hunger, sans article → keinen Hunger.", en: "der Hunger, no article → keinen Hunger." } },
      { q: "Das Wetter ist ___ gut.", opts: ["nicht", "kein", "keine"], a: 0, why: { fr: "On nie un adjectif → nicht.", en: "Negating an adjective → nicht." } },
      { q: "Wir haben ___ Kinder.", opts: ["kein", "keine", "nicht"], a: 1, why: { fr: "Pluriel → keine.", en: "Plural → keine." } },
      { q: "Er kommt heute ___.", opts: ["kein", "nicht", "keinen"], a: 1, why: { fr: "On nie le verbe → nicht.", en: "Negating the verb → nicht." } },
      { q: "Sie trinkt ___ Milch.", opts: ["keine", "nicht", "kein"], a: 0, why: { fr: "die Milch, sans article → keine Milch.", en: "die Milch, no article → keine Milch." } },
    ] },

  { id: "g07", de: "Satzbau und Fragen", fr: "L’ordre des mots et les questions", en: "Word order and questions",
    intro: {
      fr: "<p>Dans la phrase déclarative, le <b>verbe conjugué est en 2e position</b> : <i>Ich <b>trinke</b> heute Kaffee. / Heute <b>trinke</b> ich Kaffee.</i></p><p>Questions avec mot interrogatif (W-Fragen : <b>wer, was, wo, woher, wohin, wann, wie, warum</b>) : verbe en 2e position. Questions oui/non : <b>verbe en 1re position</b> : <i><b>Trinkst</b> du Kaffee?</i></p>",
      en: "<p>In a statement, the <b>conjugated verb is in 2nd position</b>: <i>Ich <b>trinke</b> heute Kaffee. / Heute <b>trinke</b> ich Kaffee.</i></p><p>W-questions (<b>wer, was, wo, woher, wohin, wann, wie, warum</b>): verb in 2nd position. Yes/no questions: <b>verb first</b>: <i><b>Trinkst</b> du Kaffee?</i></p>" },
    tables: [{ head: ["Position 1", "Position 2 (Verb)", "Rest"], rows: [["Ich", "wohne", "in Köln."], ["Heute", "wohne", "ich in Köln."], ["Wo", "wohnst", "du?"], ["—", "Wohnst", "du in Köln?"]] }],
    examples: [["Woher kommen Sie?", "D’où venez-vous ?", "Where are you from?"], ["Am Montag arbeite ich.", "Le lundi, je travaille.", "On Monday I work."]],
    ex: [
      { q: "Heute ___ ich ins Kino.", opts: ["gehe", "ich gehe", "gehen"], a: 0, why: { fr: "Verbe en 2e position, puis le sujet.", en: "Verb in 2nd position, then the subject." } },
      { q: "___ wohnst du? – In Wien.", opts: ["Wer", "Wo", "Wann"], a: 1, why: { fr: "Lieu → wo.", en: "Place → wo." } },
      { q: "___ kommst du? – Aus Frankreich.", opts: ["Woher", "Wohin", "Wie"], a: 0, why: { fr: "Origine → woher.", en: "Origin → woher." } },
      { q: "___ du Deutsch?", opts: ["Sprichst", "Du sprichst", "Spricht"], a: 0, why: { fr: "Question oui/non : verbe en 1re position.", en: "Yes/no question: verb first." } },
      { q: "___ beginnt der Kurs? – Um neun.", opts: ["Wo", "Wann", "Was"], a: 1, why: { fr: "Moment → wann.", en: "Time → wann." } },
    ] },

  { id: "g08", de: "Modalverben", fr: "Les verbes de modalité", en: "Modal verbs",
    intro: {
      fr: "<p><b>können</b> (pouvoir/savoir), <b>müssen</b> (devoir), <b>wollen</b> (vouloir), <b>dürfen</b> (avoir le droit), <b>sollen</b> (devoir, conseil) et <b>möchten</b> (aimerait). Ils changent de voyelle au singulier et <b>ich = er</b> (pas de -t) : ich kann, er kann.</p><p>Le verbe principal va <b>à la fin, à l’infinitif</b> : <i>Ich <b>kann</b> heute nicht <b>kommen</b>.</i></p>",
      en: "<p><b>können</b> (can), <b>müssen</b> (must), <b>wollen</b> (want), <b>dürfen</b> (may), <b>sollen</b> (should) and <b>möchten</b> (would like). Their vowel changes in the singular and <b>ich = er</b> (no -t): ich kann, er kann.</p><p>The main verb goes <b>to the end, in the infinitive</b>: <i>Ich <b>kann</b> heute nicht <b>kommen</b>.</i></p>" },
    tables: [{ head: ["", "können", "müssen", "wollen", "möchten"], rows: [["ich", "kann", "muss", "will", "möchte"], ["du", "kannst", "musst", "willst", "möchtest"], ["er/sie/es", "kann", "muss", "will", "möchte"], ["wir", "können", "müssen", "wollen", "möchten"], ["ihr", "könnt", "müsst", "wollt", "möchtet"], ["sie/Sie", "können", "müssen", "wollen", "möchten"]] }],
    examples: [["Kannst du mir helfen?", "Tu peux m’aider ?", "Can you help me?"], ["Ich muss heute arbeiten.", "Je dois travailler aujourd’hui.", "I have to work today."], ["Ich möchte ein Brot kaufen.", "J’aimerais acheter un pain.", "I’d like to buy a loaf."]],
    ex: [
      { q: "Er ___ gut schwimmen.", opts: ["kannt", "kann", "können"], a: 1, why: { fr: "er kann (pas de -t).", en: "er kann (no -t)." } },
      { q: "Ich muss heute ___.", opts: ["arbeite", "arbeiten", "arbeitet"], a: 1, why: { fr: "Infinitif à la fin.", en: "Infinitive at the end." } },
      { q: "___ du einen Kaffee?", opts: ["Möchtest", "Möchte", "Möchtet"], a: 0, why: { fr: "du möchtest.", en: "du möchtest." } },
      { q: "Wir ___ ins Kino gehen.", opts: ["will", "wollt", "wollen"], a: 2, why: { fr: "wir wollen.", en: "wir wollen." } },
      { q: "Hier ___ man nicht rauchen.", opts: ["darf", "darfst", "dürft"], a: 0, why: { fr: "man = er → darf.", en: "man = er → darf." } },
    ] },

  { id: "g09", de: "Trennbare Verben", fr: "Les verbes à particule séparable", en: "Separable verbs",
    intro: {
      fr: "<p>Certains verbes ont une particule (<b>an-, auf-, ein-, mit-, ab-, fern-…</b>) qui se place <b>à la fin de la phrase</b> au présent : <i>aufstehen → Ich <b>stehe</b> um sieben <b>auf</b>.</i></p><p>Avec un modal, le verbe reste entier à la fin : <i>Ich muss um sieben <b>aufstehen</b>.</i> Au parfait, <b>ge</b> se place entre les deux : <i>auf<b>ge</b>standen, ein<b>ge</b>kauft</i>.</p>",
      en: "<p>Some verbs have a prefix (<b>an-, auf-, ein-, mit-, ab-, fern-…</b>) that goes <b>to the end of the sentence</b> in the present: <i>aufstehen → Ich <b>stehe</b> um sieben <b>auf</b>.</i></p><p>With a modal verb it stays whole at the end: <i>Ich muss um sieben <b>aufstehen</b>.</i> In the perfect, <b>ge</b> goes in between: <i>auf<b>ge</b>standen, ein<b>ge</b>kauft</i>.</p>" },
    tables: [{ head: ["Infinitiv", "Präsens", "Perfekt"], rows: [["einkaufen", "Ich kaufe heute ein.", "Ich habe eingekauft."], ["anrufen", "Ich rufe dich an.", "Ich habe dich angerufen."], ["aufstehen", "Er steht früh auf.", "Er ist früh aufgestanden."]] }],
    examples: [["Der Zug kommt um zehn an.", "Le train arrive à dix heures.", "The train arrives at ten."], ["Kommst du mit?", "Tu viens avec nous ?", "Are you coming along?"]],
    ex: [
      { q: "Ich ___ am Samstag ___. (einkaufen)", opts: ["kaufe … ein", "einkaufe … –", "ein … kaufe"], a: 0, why: { fr: "La particule « ein » va à la fin.", en: "The prefix “ein” goes to the end." } },
      { q: "Wann stehst du ___?", opts: ["an", "auf", "mit"], a: 1, why: { fr: "aufstehen → stehst … auf.", en: "aufstehen → stehst … auf." } },
      { q: "Ich muss morgen früh ___.", opts: ["aufstehen", "stehe auf", "aufstehe"], a: 0, why: { fr: "Avec un modal : infinitif entier à la fin.", en: "With a modal: whole infinitive at the end." } },
      { q: "Ich habe dich gestern ___.", opts: ["geanrufen", "angerufen", "anrufen"], a: 1, why: { fr: "Partizip II : an-ge-rufen.", en: "Participle: an-ge-rufen." } },
      { q: "Am Abend ___ ich ___. (fernsehen)", opts: ["sehe … fern", "fernsehe … –", "fern … sehe"], a: 0, why: { fr: "sehe … fern.", en: "sehe … fern." } },
    ] },

  { id: "g10", de: "Possessivartikel", fr: "Les déterminants possessifs", en: "Possessive articles",
    intro: {
      fr: "<p><b>mein</b> (mon), <b>dein</b> (ton), <b>sein</b> (son, à lui), <b>ihr</b> (son, à elle), <b>unser</b> (notre), <b>euer</b> (votre, à vous tous), <b>ihr</b> (leur), <b>Ihr</b> (votre, politesse).</p><p>Ils se déclinent comme <b>ein/kein</b> : <i>mein Bruder, meine Schwester, mein Kind, meine Eltern ; Akk. : meinen Bruder</i>.</p>",
      en: "<p><b>mein</b> (my), <b>dein</b> (your), <b>sein</b> (his), <b>ihr</b> (her), <b>unser</b> (our), <b>euer</b> (your, plural), <b>ihr</b> (their), <b>Ihr</b> (your, polite).</p><p>They change like <b>ein/kein</b>: <i>mein Bruder, meine Schwester, mein Kind, meine Eltern; acc.: meinen Bruder</i>.</p>" },
    tables: [{ head: ["", "der", "die", "das", "Plural"], rows: [["Nominativ", "mein Vater", "meine Mutter", "mein Kind", "meine Eltern"], ["Akkusativ", "<b>meinen</b> Vater", "meine Mutter", "mein Kind", "meine Eltern"]] }],
    examples: [["Das ist meine Schwester.", "C’est ma sœur.", "This is my sister."], ["Wie ist Ihr Name?", "Quel est votre nom ?", "What is your name?"], ["Anna besucht ihren Vater.", "Anna rend visite à son père.", "Anna visits her father."]],
    ex: [
      { q: "Das ist ___ Mutter. (ich)", opts: ["mein", "meine", "meinen"], a: 1, why: { fr: "die Mutter → meine.", en: "die Mutter → meine." } },
      { q: "Tom ruft ___ Freundin an. (à lui)", opts: ["seine", "ihre", "sein"], a: 0, why: { fr: "Possesseur masculin (Tom) → sein ; die Freundin → seine.", en: "Male owner (Tom) → sein; die Freundin → seine." } },
      { q: "Wir besuchen ___ Großvater.", opts: ["unser", "unseren", "unsere"], a: 1, why: { fr: "der Großvater, accusatif → unseren.", en: "der Großvater, accusative → unseren." } },
      { q: "Wie ist ___ Adresse, Frau Kim?", opts: ["Ihre", "deine", "ihr"], a: 0, why: { fr: "Politesse → Ihre (majuscule).", en: "Polite → Ihre (capital I)." } },
      { q: "Maria sucht ___ Schlüssel. (à elle)", opts: ["seinen", "ihren", "ihre"], a: 1, why: { fr: "Possesseur féminin → ihr ; der Schlüssel, Akk. → ihren.", en: "Female owner → ihr; der Schlüssel, acc. → ihren." } },
    ] },

  { id: "g11", de: "Präpositionen mit Dativ", fr: "Les prépositions suivies du datif", en: "Prepositions with the dative",
    intro: {
      fr: "<p><b>mit, bei, nach, von, zu, aus, seit</b> sont toujours suivies du <b>datif</b> : der/das → <b>dem</b>, die → <b>der</b>, pluriel → <b>den</b> (+n).</p><p>Contractions courantes : <b>zu dem → zum</b>, <b>zu der → zur</b>, <b>bei dem → beim</b>, <b>von dem → vom</b>. <i>Ich fahre <b>mit dem</b> Bus <b>zum</b> Bahnhof.</i></p>",
      en: "<p><b>mit, bei, nach, von, zu, aus, seit</b> always take the <b>dative</b>: der/das → <b>dem</b>, die → <b>der</b>, plural → <b>den</b> (+n).</p><p>Common contractions: <b>zu dem → zum</b>, <b>zu der → zur</b>, <b>bei dem → beim</b>, <b>von dem → vom</b>. <i>Ich fahre <b>mit dem</b> Bus <b>zum</b> Bahnhof.</i></p>" },
    tables: [{ head: ["", "der", "die", "das", "Plural"], rows: [["Nominativ", "der Bus", "die Bahn", "das Auto", "die Freunde"], ["Dativ", "<b>dem</b> Bus", "<b>der</b> Bahn", "<b>dem</b> Auto", "<b>den</b> Freunde<b>n</b>"]] }],
    examples: [["Ich gehe zum Arzt.", "Je vais chez le médecin.", "I’m going to the doctor."], ["Sie wohnt bei ihrer Tante.", "Elle habite chez sa tante.", "She lives with her aunt."], ["Ich komme aus der Schweiz.", "Je viens de Suisse.", "I come from Switzerland."]],
    ex: [
      { q: "Ich fahre mit ___ Fahrrad.", opts: ["das", "dem", "den"], a: 1, why: { fr: "mit + datif ; das Fahrrad → dem.", en: "mit + dative; das Fahrrad → dem." } },
      { q: "Wir gehen ___ Bäckerei.", opts: ["zur", "zum", "zu die"], a: 0, why: { fr: "die Bäckerei → zu der = zur.", en: "die Bäckerei → zu der = zur." } },
      { q: "Ich gehe ___ Bahnhof.", opts: ["zur", "zum", "zu den"], a: 1, why: { fr: "der Bahnhof → zu dem = zum.", en: "der Bahnhof → zu dem = zum." } },
      { q: "Das Geschenk ist von ___ Mutter.", opts: ["meine", "meiner", "meinem"], a: 1, why: { fr: "von + datif ; die Mutter → meiner.", en: "von + dative; die Mutter → meiner." } },
      { q: "Er spielt mit ___ Kindern.", opts: ["die", "den", "dem"], a: 1, why: { fr: "Pluriel datif → den Kindern.", en: "Dative plural → den Kindern." } },
    ] },

  { id: "g12", de: "Das Perfekt", fr: "Le passé composé (Perfekt)", en: "The perfect tense",
    intro: {
      fr: "<p>À l’oral, on raconte le passé au <b>Perfekt</b> : <b>haben</b> ou <b>sein</b> (conjugué, 2e position) + <b>Partizip II</b> à la fin.</p><p>Partizip II : verbes réguliers <b>ge-…-t</b> (gemacht, gekauft) ; irréguliers <b>ge-…-en</b> (gegessen, gefahren) ; verbes en <b>-ieren</b> et à préfixe inséparable sans ge- (studiert, verstanden, bezahlt).</p><p><b>sein</b> avec les verbes de déplacement ou de changement d’état (gehen, fahren, kommen, aufstehen) et avec sein/bleiben.</p>",
      en: "<p>In speech, the past is told in the <b>perfect</b>: <b>haben</b> or <b>sein</b> (conjugated, 2nd position) + <b>past participle</b> at the end.</p><p>Participle: regular verbs <b>ge-…-t</b> (gemacht, gekauft); irregular <b>ge-…-en</b> (gegessen, gefahren); verbs in <b>-ieren</b> and with inseparable prefixes take no ge- (studiert, verstanden, bezahlt).</p><p>Use <b>sein</b> with verbs of movement or change of state (gehen, fahren, kommen, aufstehen) and with sein/bleiben.</p>" },
    tables: [{ head: ["Infinitiv", "Hilfsverb", "Partizip II"], rows: [["kaufen", "haben", "gekauft"], ["essen", "haben", "gegessen"], ["fahren", "sein", "gefahren"], ["aufstehen", "sein", "aufgestanden"], ["bezahlen", "haben", "bezahlt"], ["studieren", "haben", "studiert"]] }],
    examples: [["Ich habe ein Brot gekauft.", "J’ai acheté un pain.", "I bought a loaf of bread."], ["Wir sind nach Berlin gefahren.", "Nous sommes allés à Berlin.", "We went to Berlin."]],
    ex: [
      { q: "Ich ___ gestern Pizza gegessen.", opts: ["bin", "habe", "hat"], a: 1, why: { fr: "essen → haben.", en: "essen → haben." } },
      { q: "Sie ___ mit dem Zug gefahren.", opts: ["ist", "hat", "sind"], a: 0, why: { fr: "Déplacement → sein.", en: "Movement → sein." } },
      { q: "Wir haben Deutsch ___.", opts: ["gelernen", "gelernt", "lernt"], a: 1, why: { fr: "Régulier : ge-lern-t.", en: "Regular: ge-lern-t." } },
      { q: "Hast du schon ___? (bezahlen)", opts: ["gebezahlt", "bezahlt", "bezahlen"], a: 1, why: { fr: "Préfixe be- : pas de ge-.", en: "Prefix be-: no ge-." } },
      { q: "Er ___ um sechs Uhr aufgestanden.", opts: ["hat", "ist", "war"], a: 1, why: { fr: "aufstehen → sein.", en: "aufstehen → sein." } },
    ] },

  { id: "g13", de: "Der Imperativ", fr: "L’impératif", en: "The imperative",
    intro: {
      fr: "<p><b>du</b> : radical du verbe, sans pronom (<i>Komm! Mach!</i>) ; les verbes en e → i gardent le i (<i>Nimm! Gib! Lies!</i>), mais pas d’umlaut (<i>Fahr!</i>). <b>ihr</b> : forme du présent sans pronom (<i>Kommt!</i>). <b>Sie</b> : infinitif + Sie (<i>Kommen Sie!</i>).</p><p>On adoucit avec <b>bitte</b> et <b>doch / mal</b> : <i>Komm bitte mal her!</i></p>",
      en: "<p><b>du</b>: verb stem, no pronoun (<i>Komm! Mach!</i>); e → i verbs keep the i (<i>Nimm! Gib! Lies!</i>), but no umlaut (<i>Fahr!</i>). <b>ihr</b>: present form without pronoun (<i>Kommt!</i>). <b>Sie</b>: infinitive + Sie (<i>Kommen Sie!</i>).</p><p>Soften it with <b>bitte</b> and <b>doch / mal</b>: <i>Komm bitte mal her!</i></p>" },
    tables: [{ head: ["", "du", "ihr", "Sie"], rows: [["kommen", "Komm!", "Kommt!", "Kommen Sie!"], ["nehmen", "Nimm!", "Nehmt!", "Nehmen Sie!"], ["fahren", "Fahr!", "Fahrt!", "Fahren Sie!"], ["sein", "Sei!", "Seid!", "Seien Sie!"]] }],
    examples: [["Nimm bitte eine Jacke mit!", "Prends une veste, s’il te plaît !", "Please take a jacket!"], ["Sprechen Sie bitte langsam!", "Parlez lentement, s’il vous plaît !", "Please speak slowly!"]],
    ex: [
      { q: "___ mir bitte das Salz! (geben, du)", opts: ["Gebe", "Gib", "Gibst"], a: 1, why: { fr: "geben → du gibst → Gib!", en: "geben → du gibst → Gib!" } },
      { q: "___ Sie bitte Platz! (nehmen)", opts: ["Nimm", "Nehmen", "Nehmt"], a: 1, why: { fr: "Sie → infinitif + Sie.", en: "Sie → infinitive + Sie." } },
      { q: "Kinder, ___ leise! (sein)", opts: ["seid", "sind", "sei"], a: 0, why: { fr: "ihr → seid!", en: "ihr → seid!" } },
      { q: "___ langsam! (fahren, du)", opts: ["Fähr", "Fahr", "Fährst"], a: 1, why: { fr: "Pas d’umlaut à l’impératif : Fahr!", en: "No umlaut in the imperative: Fahr!" } },
      { q: "___ das Buch! (lesen, du)", opts: ["Lies", "Les", "Liest"], a: 0, why: { fr: "lesen → Lies!", en: "lesen → Lies!" } },
    ] },
];
