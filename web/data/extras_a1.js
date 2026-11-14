/* Content for modules 20 (sentence building), 21 (word families), 23 (reading), 27 (thinking in German),
 * 28 (Quiz Arena: true/false and spot-the-error). Written for DeepQ, level A1. */
window.DQ_DATA = window.DQ_DATA || {};

// 21 — word families: root, members [de, fr, en]
DQ_DATA.families = [
  { root: "back-", members: [["backen", "faire cuire au four", "to bake"], ["der Bäcker", "le boulanger", "baker"], ["die Bäckerei", "la boulangerie", "bakery"], ["das Gebäck", "les viennoiseries", "pastries"]] },
  { root: "fahr-", members: [["fahren", "aller (en véhicule)", "to drive, to go"], ["die Fahrkarte", "le billet", "ticket"], ["das Fahrrad", "le vélo", "bicycle"], ["abfahren", "partir", "to depart"], ["die Abfahrt", "le départ", "departure"]] },
  { root: "kauf-", members: [["kaufen", "acheter", "to buy"], ["einkaufen", "faire les courses", "to go shopping"], ["der Verkäufer", "le vendeur", "shop assistant"], ["die Verkäuferin", "la vendeuse", "shop assistant (f)"], ["verkaufen", "vendre", "to sell"]] },
  { root: "wohn-", members: [["wohnen", "habiter", "to live"], ["die Wohnung", "l’appartement", "flat"], ["das Wohnzimmer", "le salon", "living room"], ["der Bewohner", "l’habitant", "resident"]] },
  { root: "lern- / lehr-", members: [["lernen", "apprendre", "to learn"], ["der Lehrer", "l’enseignant", "teacher"], ["die Lehrerin", "l’enseignante", "teacher (f)"], ["das Lernen", "l’apprentissage", "learning"]] },
  { root: "sprech- / sprach-", members: [["sprechen", "parler", "to speak"], ["die Sprache", "la langue", "language"], ["das Gespräch", "la conversation", "conversation"], ["die Aussprache", "la prononciation", "pronunciation"]] },
  { root: "schlaf-", members: [["schlafen", "dormir", "to sleep"], ["das Schlafzimmer", "la chambre", "bedroom"], ["müde / schläfrig", "fatigué / somnolent", "tired / sleepy"]] },
  { root: "arbeit-", members: [["arbeiten", "travailler", "to work"], ["die Arbeit", "le travail", "work"], ["arbeitslos", "au chômage", "unemployed"], ["der Mitarbeiter", "le collaborateur", "employee"]] },
];

// 20 — sentence building (correct order; the app shuffles the words)
DQ_DATA.sentences = [
  ["Ich trinke morgens einen Kaffee.", "Je bois un café le matin.", "I drink a coffee in the morning."],
  ["Heute gehe ich in die Bäckerei.", "Aujourd’hui, je vais à la boulangerie.", "Today I’m going to the bakery."],
  ["Wo wohnst du?", "Où habites-tu ?", "Where do you live?"],
  ["Ich hätte gern zwei Brötchen.", "J’aimerais deux petits pains.", "I’d like two rolls."],
  ["Am Samstag kaufe ich ein.", "Le samedi, je fais les courses.", "On Saturday I go shopping."],
  ["Ich kann heute nicht kommen.", "Je ne peux pas venir aujourd’hui.", "I can’t come today."],
  ["Wir haben gestern Pizza gegessen.", "Nous avons mangé de la pizza hier.", "We ate pizza yesterday."],
  ["Sprechen Sie bitte langsam.", "Parlez lentement, s’il vous plaît.", "Please speak slowly."],
  ["Der Zug kommt um zehn Uhr an.", "Le train arrive à dix heures.", "The train arrives at ten o’clock."],
  ["Mein Bruder arbeitet in einem Büro.", "Mon frère travaille dans un bureau.", "My brother works in an office."],
  ["Kannst du mir bitte helfen?", "Peux-tu m’aider, s’il te plaît ?", "Can you help me, please?"],
  ["Ich fahre mit dem Bus zum Bahnhof.", "Je vais à la gare en bus.", "I take the bus to the station."],
];

// 23 — reading texts (A1). Words are looked up in the dictionary; gloss gives help for other words.
DQ_DATA.texts = [
  { id: "t1", title: "Samstagmorgen", level: "A1",
    de: "Es ist Samstag. Anna steht um acht Uhr auf. Sie hat Hunger, aber der Kühlschrank ist leer. Sie geht in die Bäckerei an der Ecke. Die Verkäuferin ist sehr freundlich. Anna kauft zwei Brötchen und ein Croissant. Das macht zwei Euro zwanzig. Dann trinkt sie zu Hause einen Kaffee und liest die Zeitung.",
    q: [["Wann steht Anna auf?", ["Um sieben Uhr", "Um acht Uhr", "Um zehn Uhr"], 1], ["Was kauft Anna?", ["Ein Brot", "Zwei Brötchen und ein Croissant", "Einen Kuchen"], 1], ["Wie viel bezahlt sie?", ["2,20 €", "2,02 €", "12,20 €"], 0]],
    gloss: { "Hunger": ["la faim", "hunger"], "dann": ["ensuite", "then"], "zu Hause": ["à la maison", "at home"] } },
  { id: "t2", title: "Meine Familie", level: "A1",
    de: "Ich heiße Paul und ich wohne in Köln. Meine Familie ist nicht groß. Mein Vater ist Lehrer und meine Mutter arbeitet im Krankenhaus. Ich habe eine Schwester. Sie heißt Lea und ist zwölf Jahre alt. Wir haben auch einen Hund. Er heißt Bruno und schläft gern auf dem Sofa.",
    q: [["Wo wohnt Paul?", ["In Köln", "In Berlin", "In Wien"], 0], ["Was ist der Vater von Beruf?", ["Arzt", "Lehrer", "Bäcker"], 1], ["Wer schläft gern auf dem Sofa?", ["Lea", "Die Mutter", "Der Hund"], 2]],
    gloss: { "auch": ["aussi", "also"] } },
  { id: "t3", title: "Mit dem Zug nach München", level: "A1",
    de: "Herr Kaya fährt am Montag nach München. Der Zug fährt um neun Uhr ab. Er kauft eine Fahrkarte am Bahnhof. Die Fahrkarte ist teuer: sie kostet neunundvierzig Euro. Im Zug trinkt er einen Tee und arbeitet am Computer. Der Zug kommt um vierzehn Uhr in München an.",
    q: [["Wann fährt der Zug ab?", ["Um neun Uhr", "Um vierzehn Uhr", "Am Dienstag"], 0], ["Was kostet die Fahrkarte?", ["19 €", "49 €", "94 €"], 1], ["Was macht Herr Kaya im Zug?", ["Er schläft.", "Er liest ein Buch.", "Er arbeitet am Computer."], 2]],
    gloss: { "neunundvierzig": ["quarante-neuf", "forty-nine"], "vierzehn": ["quatorze", "fourteen"] } },
];

// 27 — think in German: an image (emoji scene) and a question to answer directly in German
DQ_DATA.think = [
  { scene: "🏠🌳☀️🐕", q: "Beschreib das Bild. Was siehst du?", hint: ["Ich sehe …", "Das Wetter ist …", "Der Hund …"], model: "Ich sehe ein Haus und einen Baum. Die Sonne scheint. Ein Hund spielt im Garten." },
  { scene: "🍞🥐☕🧾", q: "Du bist in der Bäckerei. Was kaufst du?", hint: ["Ich hätte gern …", "Und …, bitte.", "Was kostet …?"], model: "Ich hätte gern ein Brot und ein Croissant. Und einen Kaffee, bitte. Was kostet das?" },
  { scene: "👨‍👩‍👧‍👦🏡", q: "Erzähl von deiner Familie.", hint: ["Meine Familie ist …", "Ich habe …", "Mein Vater / Meine Mutter …"], model: "Meine Familie ist klein. Ich habe einen Bruder. Meine Mutter arbeitet in einem Büro." },
  { scene: "⏰🚿☕🚌", q: "Wie ist dein Morgen? Was machst du zuerst?", hint: ["Ich stehe um … auf.", "Dann …", "Ich fahre mit …"], model: "Ich stehe um sieben Uhr auf. Dann dusche ich und trinke einen Kaffee. Ich fahre mit dem Bus zur Arbeit." },
  { scene: "🌧️☂️🏙️", q: "Wie ist das Wetter heute? Was machst du?", hint: ["Heute regnet es / ist es …", "Ich bleibe …", "Ich nehme …"], model: "Heute regnet es und es ist kalt. Ich nehme einen Regenschirm und gehe in die Stadt." },
  { scene: "🎂🎉🎁", q: "Wann hast du Geburtstag? Was machst du an deinem Geburtstag?", hint: ["Ich habe im … Geburtstag.", "Ich mache …", "Meine Freunde …"], model: "Ich habe im Mai Geburtstag. Ich mache eine Party und meine Freunde kommen." },
];

// 28 — true/false statements and spot-the-error sentences for the Quiz Arena
DQ_DATA.truefalse = [
  ["Das Wort „Brötchen“ ist neutral: das Brötchen.", true, "-chen → das.", "-chen → das."],
  ["Der Plural von „Kind“ ist „Kinds“.", false, "Kind → Kinder.", "Kind → Kinder."],
  ["„Tschüss“ sagt man zum Abschied.", true, "Tschüss = salut, au revoir.", "Tschüss = bye."],
  ["Nach „mit“ steht der Akkusativ.", false, "mit + Dativ : mit dem Bus.", "mit + dative: mit dem Bus."],
  ["„Ich hätte gern …“ ist höflich.", true, "Konjunktiv II de politesse.", "Polite Konjunktiv II."],
  ["Die Woche hat acht Tage.", false, "Sieben Tage.", "Seven days."],
  ["„Gute Nacht“ sagt man am Morgen.", false, "Am Morgen : Guten Morgen.", "In the morning: Guten Morgen."],
  ["Das Verb steht im Aussagesatz an Position 2.", true, "Verbe en 2e position.", "Verb in 2nd position."],
  ["„fahren“ bildet das Perfekt mit „sein“.", true, "Ich bin gefahren.", "Ich bin gefahren."],
  ["Der Plural von „die Frau“ ist „die Frauen“.", true, "-en.", "-en."],
];
DQ_DATA.errors = [
  { s: ["Ich", "habe", "einen", "Brot", "gekauft."], bad: 2, fix: "ein", why: ["das Brot → ein Brot (neutre).", "das Brot → ein Brot (neuter)."] },
  { s: ["Er", "kann", "gut", "schwimmt."], bad: 3, fix: "schwimmen", why: ["Après un modal : infinitif.", "After a modal: infinitive."] },
  { s: ["Wir", "fahren", "mit", "den", "Bus."], bad: 3, fix: "dem", why: ["mit + datif : dem Bus.", "mit + dative: dem Bus."] },
  { s: ["Heute", "ich", "gehe", "ins", "Kino."], bad: 1, fix: "gehe ich", why: ["Verbe en 2e position : Heute gehe ich …", "Verb second: Heute gehe ich …"] },
  { s: ["Ich", "bin", "gestern", "Pizza", "gegessen."], bad: 1, fix: "habe", why: ["essen → haben.", "essen → haben."] },
  { s: ["Zwei", "Brötchens,", "bitte."], bad: 1, fix: "Brötchen,", why: ["Pas de -s : zwei Brötchen.", "No -s: zwei Brötchen."] },
  { s: ["Du", "sprechst", "sehr", "gut", "Deutsch."], bad: 1, fix: "sprichst", why: ["sprechen → du sprichst.", "sprechen → du sprichst."] },
  { s: ["Ich", "habe", "kein", "Zeit."], bad: 2, fix: "keine", why: ["die Zeit → keine Zeit.", "die Zeit → keine Zeit."] },
];
