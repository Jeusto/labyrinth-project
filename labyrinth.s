.data

	# Tous les textes qui peuvent être affichées
	TxtMenuChoix:
		.asciiz "  Veuillez faire un choix :\n\n	 1 : Générer un labyrinthe\n	 2 : Résoudre un labyrinthe\n	 3 : Quitter le programme\n\n  Entrez votre choix :  "
	TxtErreurMenuChoix:
		.asciiz "\n  /!\\ Erreur : Il faut choisir 1, 2 ou 3 /!\\ \n\n"
	TxtDemanderTaille:
		.asciiz "  Choisissez la taille du labyrinthe : "
	TxtErreurDemanderTaille:
		.asciiz "\n  /!\\ Erreur : La taille du labyrinthe doit être supérieur à 2 /!\\ \n\n"
	TxtDemanderNom:
		.asciiz "  Choisissez le nom du fichier (sans l'extension): "
	TxtErreurNom:
		.asciiz "\n  /!\\ Erreur : Impossible d'ouvrir le fichier /!\\ \n\n"
	TxtLabyrintheCree:
		.asciiz "\n  Le fichier du labyrinthe a été crée.\n  Faites ./print_maze.sh <fichier_labyrinthe> pour le visualiser.\n"
	TxtLabyrintheResolu:
		.asciiz "\n  Le fichier du labyrinthe résolu a été crée.\n  Faites ./print_maze.sh <fichier_labyrinthe> pour le visualiser.\n"
	TxtExtensionResolu:
		.asciiz ".resolu"
	TxtExtensionTxt:
		.asciiz ".txt"
	TxtNouveauLigne:
		.asciiz "\n"




.text
.globl __start

# Début du programme
__start:

	# On récupère l'heure du système d'exploitaion
	li	$v0	30
	syscall # Appel système : system time
	li	$a0	0

	# On l'utilise en tant que seed pour le générateur de nombres pseudo-aléatoires
	move	$a1	$v0
	li	$v0	40
	syscall # Appel système : set seed

	# On passe à la fonction pour afficher le menu et demander le mode
	jal	Menu




# Affichage et gestion du menu
Menu:

	# On affiche le texte du menu
	la	$a0	TxtMenuChoix
	li	$v0	4
	syscall # Appel système : print string
	# On stocke le choix de mode de l'utilisateur dans $v0
	# (1 = mode génération, 2 = mode résolution, 3 = quitter le programme)
	li	$v0	5
	syscall # Appel système : read integer

	# On saute à la fonction génération ou résolution en fonction du choix de l'utilisateur
	# On saute en mode génération
	beq	$v0	1	Mode_Generation
	# On saute en mode résolution
	beq	$v0	2	Mode_Resolution
	# On quitte le programme
	beq	$v0	3 Exit

	# On affiche le texte d'erreur si la réponse est différent de 1,2 et 3
	li	$v0	4
	la	$a0	TxtErreurMenuChoix
	syscall # Appel système : print string
	# On redemande tant que la réponse n'est pas 1 ou 2
	j	Menu




# Mode pour générer le labyrinthe
Mode_Generation:

	# On demande la taille du labyrinthe
	jal	Demander_Taille
	move	$s1	$v0		# $s1 : taille du labyrinthe

	# On demande le nom du fichier et on ouvre le descripteur de fichier
	jal	Mode_Generation_Descripteur_Fichier
	move	$s2	$v0 	# $s2 : descripteur de fichier pour écrire le labyrinthe

	# On alloue la mémoire pour le tableau correspondant au labyrinthe
	move	$a0	$s1	 # $a0 : adresse du tableau
	jal	Creer_Tableau
	move	$s0	$v0		# $s0 : adresse du tableau

	# On génére l'entrée et la sortie du labyrinthe
	move	$a0	$s0 	# $a0 : adresse du tableau
	move	$a1	$s1 	# $a1 : taille du tableau
	jal	Generer_Entree_Sortie

	# On génére le labyrinthe
	move	$a0	$s0 	# $a0 : adresse du tableau
	move	$a1	$s1 	# $a1 : taille du tableau
	move	$a2	$v0		# $v0 = coordonnée y de l'entrée
	move	$a3	$v1		# $v1 = coordonnée x de l'entrée
	jal	Generer_Labyrinthe

	# On met tous les bits de poids 7 (qui indique si la case a été visitée) à 0
	move	$a0	$s0		# $a0 : adresse du tableau
	move	$a1	$s1		# $a1 : taille du tableau
	li	$a2	7
	jal	Desactiver_Tout_Bits

	# On enregistre le labyrinthe dans le fichier
	move	$a0	$s0		# $a0 : adresse du tableau
	move	$a1	$s1		# $a1 : taille du tableau
	move	$a2	$s2		# $a2 : descripteur de fichier pour écrire dans le fichier
	jal	Enregistrer_Fichier

	# On affiche que le fichier du labyrinthe a été crée
	li $v0 4
	la $a0 TxtLabyrintheCree
	syscall

	# On quitte le programme
	j	Exit




# Mode pour résoudre le labyrinthe
Mode_Resolution:

	# On ouvre les descripteurs de fichier pour lire et écrire dans le fichier
	jal	Mode_Resolution_Descripteur_Fichier
	move	$s2	$v0		# $s3 : descripteur de fichier pour lire le fichier
	move	$s3	$v1		# $s3 : descripteur de fichier pour écrire dans le fichier

	# On analyse le fichier du labyrinthe
	move	$a0	$s2		# $a0 : descripteur de fichier pour lire le fichier
	jal	Analyser_Fichier
	move	$s0	$v0		# $s0 : adresse du tableau
	move	$s1	$v1		# $s1 : taille du tableau

	# On trouve l'entrée dans le labyrinthe analysé
	move	$a0	$s0 	# $a0 : adresse du tableau
	move	$a1	$s1 	# $a1 : taille du tableau
	jal	Trouver_Entree

	# On résout le labyrinthe
	move	$a0	$s0		# $a0 : adresse du tableau
	move	$a1	$s1		# $a1 : taille du tableau
	move	$a2	$v0 	# $a2	: coordonnée x de la case d'entrée
	move	$a3	$v1 	# $a3	: coordonnée x de la case d'entrée
	jal	Resoudre_Labyrinthe

	# On enlève la marque qui dit que la case a été visitée
	move	$a0	$s0 	# $a0 : adresse du tableau
	move	$a1	$s1 	# $a1 : taille du tableau
	li	$a2	7 			# $a2 : 7 (bit le plus fort)
	jal	Desactiver_Tout_Bits

	# On affiche que le fichier du labyrinthe résolu a été crée
	li $v0 4
	la $a0 TxtLabyrintheResolu
	syscall

	# On enregistre le labyrinthe résolu dans le fichier
	move	$a0	$s0 	# $a0 : adresse du tableau
	move	$a1	$s1 	# $a1 : taille du tableau
	move	$a2	$s3		# $a2 : descripteur de fichier pour écrire dans le fichier
	jal	Enregistrer_Fichier

	# On quitte le programme
	j	Exit




# Demande la taille du labyrinthe à l'utilisateur
# Renvoie :
	# $v0	= La taille du labyrinthe
Demander_Taille:

	# On affiche le texte pour demander la taille du labyrinthe
	li	$v0	4
	la	$a0	TxtDemanderTaille
	syscall # Appel système : print string

	# On récupère le choix de taille de l'utilisateur
	li	$v0	5 # Appel système : read integer
	syscall

	# On vérifie que que c'est supérieur à 1
	bgt	$v0	1 Sauter_Registre

	# On affiche le texte d'erreur si ce n'est pas supérieur à 1
	li	$v0	4
	la	$a0	TxtErreurDemanderTaille
	syscall # Appel système : print string

	# On redemande tant que la réponse n'est pas supérieur à 1
	j	Demander_Taille




# Demande le nom du fichier à l'utilisateur
# Paramètres :
	# $a0	= L'adresse qui contient la chaîne de caractères
# Renvoie
	# $v0	= La longueur de la chaîne de caractères
Demander_Nom_Fichier:

# Prologue
	subu	$sp	$sp	12
	sw	$ra	($sp)
	sw	$s0	4($sp)
	sw	$s1	8($sp)
	move	$s0	$a0	# $s0 : adresse de la mémoire tampon pour la chaine de caractères

# Corps de la fonction
	# On affiche le texte pour demander le nom du fichier
	li	$v0	4
	la	$a0	TxtDemanderNom
	syscall # Appel système : print string

	# On récupère le nom du fichier (chaine de caractères)
	li	$v0	8
	move	$a0	$s0 	# $a0 : adresse de la mémoire tampon pour la chaine de caractères
	li	$a1	500
	syscall

	# On stocke la longueur du nom du fichier dans $s1
	jal	Longueur_Nom_Fichier
	move	$s1	$v0	# $s1 : longueur de la chaine de caractères

	# On vérifie si le dernier caractère correspond à "\n"
	# et on le remplace avec le caractère nul "\0"
	addu	$t0	$s0	$s1		# $t0 : l'adresse de la fin de la chaîne de caractères
	lb	$t1	-1($t0) 		# $t1 : le dernier caractère
	lb	$t2	TxtNouveauLigne	# $t2 = "\n"

	# On vérifie si le dernier caractère est "\n"
	bne	$t1	$t2	NonTxt_NouveauLigne
	sb	$zero	-1($t0)
	# On soustrait 1 à la longueur de la chaine de caractères
	subu	$s1	$s1	1

	# On ajoute l'extension "txt" au nom du fichier
	move	$a0	$s0 	# $a0 : adresse de la mémoire tampon pour la chaine de caractères
	move	$a1	$s1 	# $a1 : longueur de la chaine de caractères
	jal	Ajouter_Extension_Txt

	NonTxt_NouveauLigne:
	# On renvoie la longueur de la chaîne de caractères (nom du fichier)
	move	$v0	$s1		# $v0 : longueur de la chaine de caractères

	# Epilogue
	lw	$ra	($sp)
	lw	$s0	4($sp)
	lw	$s1	8($sp)
	addu	$sp	$sp	12
	jr	$ra




# Donne la longueur d'une chaine de caractères (sans compter le \0)
# Paramètres :
	# $a0	= Adresse de la chaine de caractères
# Renvoie :
	# $v0	= La longueur de la chaine de caractères
Longueur_Nom_Fichier:

	li	$v0	0		# $v0 : longueur du nom du fichier initialisé à 0
	Boucle_LongueurNomFichier:
		lb	$t0	0($a0)
		beqz	$t0	Sauter_Registre
		# On ajoute 1 tant que la chaine de caractères ne se termine pas
		addi	$v0	$v0	1
		addi	$a0	$a0	1
		j	Boucle_LongueurNomFichier




# Ouvre le descripteur de fichier pour le mode génération
# Renvoie :
	# $v0	= Le descripteur de fichier pour écrire le labyrinthe
Mode_Generation_Descripteur_Fichier:

# Prologue
	subu	$sp	$sp	8
	sw	$ra	($sp)
	sw	$s0	4($sp)

# Corps de la fonction
# On alloue la mémoire tampon pour le nom du fichier
	li	$v0	9
	li	$a0	500
	syscall # Appel système : allocate heap memory
	move	$s0	$v0	# $s0 = adresse de l'espace mémoire tampon

	DescripteurFichier_Generation:
	# On demande le nom du fichier
	move	$a0	$s0 # $a0 = adresse de l'espace mémoire tampon
	jal	Demander_Nom_Fichier

	# On ouvre le fichier pour écrire le labyrinthe dessus
	li	$v0	13
	move	$a0	$s0		# $a0 : adresse de l'espace mémoire tampon
	li	$a1	1
	li	$a2	0
	syscall	# Appel système : open file

	bltz	$v0	Erreur_FichierGeneration	# Impossible de lire le fichier


# Epilogue
	lw	$ra	($sp)
	lw	$s0	4($s0)
	addu	$sp	$sp	8
	jr	$ra

	Erreur_FichierGeneration:
		li	$v0	4
		# On affiche le message d'erreur comme quoi on peut pas ouvrir le fichier
		la	$a0	TxtErreurNom
		syscall	# Appel système : print string
		# On retourne dans le corps de la fonction pour redemander le nom du fichier
		j	DescripteurFichier_Generation




# Générer le labyrinthe
# Paramètres :
	# $a0	= Adresse du tableau
	# $a1	= Taille du tableau
	# $a2	= Coordonnée x de la case d'entrée
	# $a3	= Coordonnée y de la case d'entrée
Generer_Labyrinthe:

# Prologue
	subu	$sp	$sp	32
	sw	$ra	0($sp)
	sw	$s0	4($sp)		# $s0 : adresse du tableau
	sw	$s1	8($sp)		# $s1 : taille du tableau
	sw	$s2	12($sp)		# $s2 : coordonnée x de la case d'entrée
	sw	$s3	16($sp)		# $s3 : coordonnée y de la case d'entrée
	sw	$s4	20($sp)		# $s4 : coordonnée x de la case actuelle
	sw	$s5	24($sp)		# $s5 : coordonnée y de la case actuelle
	sw	$s6	28($sp)		# $s6 : stockage temporaire de la direction

# Corps de la fonction
	# On récupère tous les arguments
	move	$s0	$a0		# $s0	: adresse du tableau
	move	$s1	$a1 	# $s1	: taille du tableau
	move	$s2	$a2 	# $s2	: coordonnée x de la case d'entrée
	move	$s3	$a3 	# $s3	: coordonnée y de la case d'entrée
	move	$s4	$a2		# $s4	: coordonnée x de la case actuelle
	move	$s5	$a3		# $s5	: coordonnée y de la case actuelle

	# On trouve l'adresse de la case d'entrée dans le tableau
	jal  Calculer_Adresse_Case
	move	$a0	$v0		# $a0 : adresse de la case d'entrée

	# On marque la case comme visité
	li	$a1	7
	jal	Activer_Bit

	# Boucle principale pour la génération
	Boucle_Generation:
		# On calcule la prochaine direction à prendre
		move	$a0	$s0 	# $a0	: adresse du tableau
		move	$a1	$s1 	# $a1	: taille du tableau
		move	$a2	$s4 	# $a2	: coordonnée x de la case actuelle
		move	$a3	$s5		# $a3	: coordonnée y de la case actuelle
		li	$t9	0
		jal	Generer_Prochaine_Direction
		move	$s6	$v0 	# $s6	: la direction à prendre

		# Si aucune direction est possible, on dépile à la case précedente
		beq	$s6	-1	VerifierDepilement_Generation

		# On empile la case actuelle
		subu	$sp	$sp	8
		sw	$s4	($sp)
		sw	$s5	4($sp)

		# On supprime le mur de la case dans la direction actuelle
		jal	Calculer_Adresse_Case
		move	$a0	$v0 	# $a0 : adresse de la case
		move	$a1	$s6 	# $a1	: la direction
		jal	Desactiver_Bit

		# On passe à la case suivante
		move	$a0	$s4 	# $a0	: coordonnée x de la case actuelle
		move	$a1	$s5		# $a1	: coordonnée y de la case actuelle
		move	$a2	$s6		# $a2	: la direction à prendre
		jal	Deplacement_Case
		move	$s4	$v0		# $s4	: coordonnée x de la case après déplacement
		move	$s5	$v1		# $s5	: coordonnée y de la case après déplacement

		# On calcule la direction opposé
		xori	$s6	$s6	2		# $s6 : la direction opposé

		# On supprime le mur et on marque la case comme visité
		move	$a0	$s0		# $a0	: adresse du tableau
		move	$a1	$s1 	# $a1	: taille du tableau
		move	$a2	$s4		# $a2	: coordonnée x de la case actuelle
		move	$a3	$s5		# $a3	: coordonnée y de la case actuelle
		jal	Calculer_Adresse_Case

		move	$a0	$v0		# $a0 : adresse de la case
		move	$a1	$s6 	# $a1	: la direction à prendre
		# On supprime le deuxième mur
		jal	Desactiver_Bit

		# On marque la case comme visité
		li	$a1	7
		jal	Activer_Bit

		# On fais une boucle pour génerer le labyrinthe
		j	Boucle_Generation

		VerifierDepilement_Generation:
		# On vérifie qu'on peut dépiler (c'est à dire qu'on est pas à l'entrée)
		bne	$s2	$s4	Depiler_Generation
		bne	$s3	$s5	Depiler_Generation
		# Si on est à l'entrée, la génération est terminé
		j	Fin_Generation

		# On dépile la case précédente
		Depiler_Generation:
		lw	$s4	($sp)
		lw	$s5	4($sp)
		addu	$sp	$sp	8
		# On fais une boucle sans re-empiler la case
		j	Boucle_Generation

# Epilogue
	Fin_Generation:
	lw	$ra	0($sp)
	lw	$s0	4($sp)
	lw	$s1	8($sp)
	lw	$s2	12($sp)
	lw	$s3	16($sp)
	lw	$s4	20($sp)
	lw	$s5	24($sp)
	lw	$s6	28($sp)
	addu	$sp	$sp	32
	jr	$ra




# Ouvre le descripteur de fichier pour le mode résolution
# Renvoie :
	# $v0	= Le descripteur de fichier utilisé pour lire le labyrinthe
	# $v1	= Le descripteur de fichier utilisé pour écrire le labyrinthe
Mode_Resolution_Descripteur_Fichier:

# Prologue
	subu	$sp	$sp	16
	sw	$ra	($sp)
	sw	$s0	4($sp)
	sw	$s1	8($sp)
	sw	$s1	12($sp)

# Corps de la fonction
	# On alloue la mémoire tampon pour le nom du fichier
	li	$v0	9
	li	$a0	500
	syscall	# Appel système : allocate heap memory
	move	$s0	$v0		# $s0 : adresse de l'espace mémoire

	DescripteurFichier_Resolution:
	# On demande le nom du fichier
	move	$a0	$s0
	jal	Demander_Nom_Fichier
	move	$s1	$v0		# $s1 : longueur du nom du fichier

	# On ouvre le fichier pour le lire
	li	$v0	13
	move	$a0	$s0 	# $s0 : adresse de l'espace mémoire
	li	$a1	0
	li	$a2	0
	syscall	# Appel système : open file

	bltz	$v0	Erreur_FichierResolution	# Impossible de lire le fichier
	move	$s2	$v0		# $s2 : descripteur de fichier utilisé pour lire le labyrinthe

	# On stocke la longueur du nom du fichier dans $s1
	jal	Longueur_Nom_Fichier
	move	$s1	$v0		# $s1 : longueur de la chaine de caractères

	# On ajoute l'extension "resolu" au nom du fichier
	move	$a0	$s0 	# $a0 : adresse de l'espace mémoire
	move	$a1	$s1		# $a1 : longueur de la chaine de caractères
	jal	Ajouter_Extension_Resolu

	# On ouvre le fichier pour écrire le labyrinthe dessus
	li	$v0	13
	move	$a0	$s0	 # $a0 : adresse de l'espace mémoire
	li	$a1	1
	li	$a2	0
	syscall # Appel système : open file

	bltz	$v0	Erreur_FichierResolution	# Impossible d'écrire sur le fichier
	move	$v1	$v0		# $v1 : descripteur de fichier utilisé pour écrire le labyrinthe
	move	$v0	$s2 	# $v0 : descripteur de fichier utilisé pour écrire le labyrinthe

# Epilogue
	lw	$ra	($sp)
	lw	$s0	4($sp)
	lw	$s1	8($sp)
	lw	$s2	12($sp)
	addu	$sp	$sp	16
	jr	$ra

	Erreur_FichierResolution:
		li	$v0	4
		# On affiche le message d'erreur comme quoi on peut pas ouvrir le fichier
		la	$a0	TxtErreurNom
		syscall # Appel système : print string
		# On retourne dans le corps de la fonction pour redemander le nom du fichier
		j	DescripteurFichier_Resolution




# Résolution du labyrinthe
	# $a0	= Adresse du tableau
	# $a1	= Taille du tableau
	# $a2	= Coordonnée x de la case d'entrée
	# $a3	= Coordonnée y de la case d'entrée
Resoudre_Labyrinthe:

# Prologue
	subu	$sp	$sp	32
	sw	$ra	0($sp)
	sw	$s0	4($sp)		# $s0 : adresse du tableau
	sw	$s1	8($sp)		# $s1 : taille du tableau
	sw	$s2	12($sp)		# $s2 : coordonnée x de la case d'entrée
	sw	$s3	16($sp)		# $s3 : coordonnée y de la case d'entrée
	sw	$s4	20($sp)		# $s4 : coordonnée x de la case actuelle
	sw	$s5	24($sp)		# $s5 : coordonnée y de la case actuelle
	sw	$s6	28($sp)		# $s6 : stockage temporaire de la direction

# Corps de la fonction
	# On récupère les arguments de la fonction
	move	$s0	$a0		# $s0	: adresse du tableau
	move	$s1	$a1 	# $s1	: taille du tableau
	move	$s2	$a2 	# $s2	: coordonnée x de la case d'entrée
	move	$s3	$a3 	# $s3	: coordonnée y de la case d'entrée
	move	$s4	$a2		# $s4	: coordonnée x de la case actuelle
	move	$s5	$a3		# $s5	: coordonnée y de la case actuelle

	# On trouve l'adresse de la case d'entrée dans le tableau
	jal	Calculer_Adresse_Case
	move	$a0	$v0 # $a0 : adresse de la case d'entrée

	# On marque la case d'entrée comme visité
	li	$a1	7
	jal	Activer_Bit

	# Boucle principale pour la résolution
	Boucle_Resolution:
		# On calcule la prochaine direction à prendre
		move	$a0	$s0 	# $a0	: adresse du tableau
		move	$a1	$s1 	# $a1	: taille du tableau
		move	$a2	$s4 	# $a2	: coordonnée x de la case actuelle
		move	$a3	$s5		# $a3	: coordonnée y de la case actuelle
		li	$t9	1
		jal	Generer_Prochaine_Direction
		move	$s6	$v0 	# $s6	: la direction à prendre

		# Si aucune direction est possible, on dépile à la case précedente
		beq	$s6	-1	Depiler_Resolution

		# On empile la case actuelle
		subu	$sp	$sp	8
		sw	$s4	($sp)
		sw	$s5	4($sp)

		# On passe à la case suivante
		move	$a0	$s4		# $a0	: coordonnée x de la case actuelle
		move	$a1	$s5		# $a1	: coordonnée y de la case actuelle
		move	$a2	$s6		# $a2	: la direction à prendre
		jal	Deplacement_Case
		move	$s4	$v0		# $s4	: coordonnée x de la case après déplacement
		move	$s5	$v1		# $s5	: coordonnée y de la case après déplacement

		# On calcule l'adresse de la case
		move	$a0	$s0		# $a0	: adresse du tableau
		move	$a1	$s1		# $a1	: taille du tableau
		move	$a2	$s4		# $a2	: coordonnée x de la case actuelle
		move	$a3	$s5		# $a3	: coordonnée y de la case actuelle
		jal	Calculer_Adresse_Case

		# On regarde si la case correspond à la sortie
		move	$a0	$v0 	# $a0	: adresse de la case actuelle
		li	$a1	5
		jal	Obtenir_Valeur_Bit

		# Si oui, on quitte la boucle, sinon on continue
		bnez	$v0	FinBoucle_Resolution

		# On le marque comme visité
		li	$a1	7
		jal	Activer_Bit

		# On fais une boucle
		j	Boucle_Resolution

		# On dépile à la case précédente (si aucune direction est possible)
		Depiler_Resolution:
		lw	$s4	($sp)
		lw	$s5	4($sp)
		addu	$sp	$sp	8

		# On fais une boucle
		j	Boucle_Resolution

	FinBoucle_Resolution:
		# On récupère les coordonnées de la dernière case
		# qui correspond au chemin de la solution, c'est le haut de la pile
		lw	$s4	($sp)
		lw	$s5	4($sp)
		addu	$sp	$sp	8

		# On calcule l'adresse de la case
		move	$a0	$s0		# $a0	: adresse du tableau
		move	$a1	$s1		# $a1	: taille du tableau
		move	$a2	$s4		# $a2	: coordonnée x de la case actuelle
		move	$a3	$s5		# $a3	: coordonnée y de la case actuelle
		jal	Calculer_Adresse_Case

		# On regarde si on est à l'entrée
		move	$a0	$v0
		li	$a1	4
		jal	Obtenir_Valeur_Bit

		# Si on est à l'entrée, on a fini de résoudre, on zappe
		bnez	$v0	Fin_Resolution

		# Sinon, on marque la case comme étant le chemin de la solution
		li	$a1	6
		jal	Activer_Bit

		# On boucle jusqu'à trouver l'entrée du labyrinthe
		j	FinBoucle_Resolution

	Fin_Resolution:

# Epilogue
	lw	$ra	0($sp)
	lw	$s0	4($sp)
	lw	$s1	8($sp)
	lw	$s2	12($sp)
	lw	$s3	16($sp)
	lw	$s4	20($sp)
	lw	$s5	24($sp)
	lw	$s6	28($sp)
	addu	$sp	$sp	32
	jr	$ra




# Crée un tableau d'une taille donnée
# Paramètres :
	# $a0	= Taille du tableau
# Renvoie :
	# $v0	= L'adresse du tableau
Creer_Tableau:

	mul	$a0	$a0	$a0
	# On alloue de l'espace mémoire sur le tas de taille $a0 * $a0
	li	$v0	9		# $v0 : adresse de l'espace mémoire
	syscall 		# Appel système : allocate heap memory

	li	$t2	0		# $t2 : décalage
	li	$t3	15  # $t3 : constant stocké

	Boucle_Augmentation:
		# On zappe si le décalage est égal à la taille du tableau (fini de créer)
		beq	$t2	$a0	Sauter_Registre
		addu	$t4	$v0	$t2		# $t4 : addresse du tableau + décalage
		sb	$t3	0($t4)
		addu	$t2	$t2	1

		# On fais une boucle
		j	Boucle_Augmentation




# Lis un entier dans le fichier
# Paramètres :
	# $a0	= Le descripteur de fichier
	# $a1	= L'adresse de la mémoire tampon pour lire l'entier
# Renvoie :
	# $v0 =	L'entier qui a été lu
Lire_Entier:

	li	$t0	0	# L'entier lu
	li	$t1	0	# Nombres de bytes qui sont lus
	li	$a2	1

	Boucle_AnalyserEntier:
		# On lis un char
		li	$v0	14
		syscall # Appel système : read from file

		# On vérifie qu'un byte a été lu
		blt	$v0	1	Fin_AnalyserInt

		# On lis depuis la mémoire tampon
		lbu	$t2	($a1)
		# On vérifie qu'un byte a été lu
		bltu	$t2	48	VerifierFin_AnalyserInt
		bgtu	$t2	57	VerifierFin_AnalyserInt

		# On incrémente le nombre de bytes qui ont été lus au total
		addu	$t1	$t1	1

		subu	$t2	$t2	48
		mulu	$t0	$t0	10
		addu	$t0	$t0	$t2
		j	Boucle_AnalyserEntier

	VerifierFin_AnalyserInt:
	# Si un byte n'a pas été lu, on retourne dans la boucle
	beqz	$t1	Boucle_AnalyserEntier

	Fin_AnalyserInt:
	move	$v0	$t0		# $v0 : Valeur de l'entier lu
	jr	$ra




# Analyse un fichier de labyrinthe
# Paramètres :
	# $a0 = Le descripteur de fichier
# Renvoie :
	# $v0	= Adresse du labyrinthe
	#	$v1	= Taille du labyrinthe
Analyser_Fichier:

	subu	$sp	$sp	28
	sw	$ra	($sp)
	sw	$s0	4($sp)		# $s0 : descripteur de fichier
	sw	$s1	8($sp)		# $s1 : taille du tableau
	sw	$s2	12($sp)		# $s2 : décalage max ($s1 * $s1 * 4)
	sw	$s3	16($sp)		# $s3 : adresse du tableau
	sw	$s4	20($sp)		# $s4 : décalage actuel
	sw	$s5	24($sp) 	# $s5 : la mémoire tampon pour lire les chars
	move	$s0	$a0			# $a0 : descripteur de fichier

	# On alloue un espace mémoire tampon de 1 byte pour lire des chars
	li	$v0	9
	li	$a0	1
	syscall	# Appel système : allocate heap memory
	move	$s5	$v0		# $s5 : adresse de la mémoire tampon

	move	$a0	$s0		# $a0 : descripteur de fichier
	move	$a1	$s5		# $s5 : adresse de la mémoire tampon pour lire les chars
	jal	Lire_Entier

	# On stocke la taille du tableau
	move	$s1	$v0		# $s1 : taille du tableau
	mulu	$s2	$s1	$s1
	mulu	$s2	$s2	4	# Décalage maximum (s1 * s1 * 4)

	# On crée le tableau
	move	$a0	$s1		# $a0 : taille du tableau
	jal	Creer_Tableau
	move	$s3	$v0		# $s3 : adresse du tableau

	li	$s4	0

	# Boucle pour analyser le labyrinthe
	Boucle_AnalyserFichier:
		move	$a0	$s0		# $s0 : descripteur de fichier
		move	$a1	$s5		# $s5 : la mémoire tampon pour lire les chars
		jal	Lire_Entier
		addu	$t0	$s3	$s4
		sb	$v0	($t0)
		addi	$s4	$s4	1
		blt	$s4	$s2	Boucle_AnalyserFichier

	# On ferme le descripteur de fichier
	li	$v0	16
	move	$a0	$s0		# $s0 : descripteur de fichier
	syscall # Appel système : close file

	# On retourne l'adresse du labyrinthe
	move	$v0	$s3		# $s3 : adresse du tableau

	# On retourne la taille du labyrinthe
	move	$v1	$s1		# $s1 : taille du tableau

	lw	$ra	($sp)
	lw	$s0	4($sp)
	lw	$s1	8($sp)
	lw	$s2	12($sp)
	lw	$s3	16($sp)
	lw	$s4	20($sp)
	lw	$s5	24($sp)
	addu	$sp	$sp	28
	jr	$ra




# Retourne un nombre aléatoire inclus dans l'intervalle [$a0,$a1[
# Paramètres :
	# $a0	= Minimum
	# $a1	= Maximum
# Pre-conditions :
	# 0 <= $a0 < $a1
# Renvoie :
	# $v0	= Entier aléatoire
Nombre_Aleatoire_Entre_Deux_Bornes:

# Prologue
	move	$t6	$a0		# $t6 = minimum
	move	$t7	$a1		# $t7 = maximum

# Corps de la fonction
	addi	$a1	$a1	1 # $a1 = maximum + 1
	move	$t0	$a0		# $t0 = borne minimum
	sub	$a0	$a1	$a0	# $a0 = maximum - min

	# L'appel système renvoie un nombre entre 0 et (maximum - minimum)
	li	$v0	42
	syscall # Appel système : random int range

	# On ajoute la borne minimum à ce nombre pour être toujours compris dans l'intervalle
	add	$v0	$a0	$t0

# Epilogue
	move	$a0	$t6
	move	$a1	$t7
	jr	$ra




# Calcule l'adresse d'une case dans le tableau
# Paramètres :
	# $a0	= Adresse du tableau
	# $a1 =	Taille du tableau
	# $a2	= Coordonnée x de la case
	# $a3 =	Coordonnée y de la case
# Renvoie:
	#	$v0	= Adresse de la case
Calculer_Adresse_Case:

	mul	$v0	$a1	$a3
	add	$v0	$v0	$a2
	add	$v0	$v0	$a0
	jr	$ra




# Génére la case d'entrée et la case de sortie du labyrinthe
# Paramètres :
	# $a0	= Adresse du tableau
	# $a1	= Taille du tableau
# Renvoie :
	# $v0 = Coordonnée y de l'entrée
	# $v1 = Coordonnée x de l'entrée
Generer_Entree_Sortie:

# Prologue
	subu	$sp	$sp	28
	sw	$ra	0($sp)
	sw	$s0	4($sp)		# $s0 : Adresse du tableau
	sw	$s1	8($sp)		# $s1 : Taille du tableau
	sw	$s2	12($sp)		# $s2 : Colonne de l'entrée (0 = entrée sur la première, 1 sinon)
	sw	$s3	16($sp)		# $s3 : Ligne de l'entrée	(coordonnée y)
	sw	$s4	20($sp)		# $s4 : Colonne de la sortie (0 = entrée sur la première, 1 sinon)
	sw	$s5	24($sp)		# $s5 : Ligne de la sortie (coordonnée y)

# Corps de la fonction
	move	$s0	$a0		# $s0 : adresse du tableau
	move	$s1	$a1		# $s1 : taille du tableau

	# On affecte les colonnes correspondant à l'entrée et la sortie
	li	$a0	0
	li	$a1	1
	jal	Nombre_Aleatoire_Entre_Deux_Bornes
	beqz	$v0	OrdreColonne_GenererSortie
		li	$s2	0
		subu	$s4	$s1	1
		j	FinOrdreColonne_GenererSortie
	OrdreColonne_GenererSortie:
		subu	$s2	$s1	1
		li	$s4	0
	FinOrdreColonne_GenererSortie:

	# On affecte les lignes correspondant à l'entrée et la sortie
	subu	$a1	$s1	1
	jal	Nombre_Aleatoire_Entre_Deux_Bornes
	move	$s3	$v0		# $s3 : ligne de l'entrée
	jal	Nombre_Aleatoire_Entre_Deux_Bornes
	move	$s5	$v0		# $s3 : ligne de l'entrée

	# On génère un nombre aléatoire entre 0 et 1
	jal	Nombre_Aleatoire_Entre_Deux_Bornes

	# Si on a 1, on échange les coordonnées ligne et colonne
	# pour que l'entrée et la sortie soit sur les bordures verticales
	beqz	$v0	NePasEchanger_EntreeSortie

		# On change l'entrée
		move	$t0	$s2
		move	$s2	$s3
		move	$s3	$t0

		# On change la sortie
		move	$t0	$s4
		move	$s4	$s5
		move	$s5	$t0

	NePasEchanger_EntreeSortie:

	move	$a0	$s0
	move	$a1	$s1
	move	$a2	$s2
	move	$a3	$s3

	# On calcule l'adresse de la case d'entrée dans le tableau
	jal	Calculer_Adresse_Case
	move	$a0	$v0		# $a0 : adresse de la case
	li	$a1	4				# $a1 : bit de poids 4 (entrée du labyrinthe)

	# On marque la case comme étant l'entrée
	jal	Activer_Bit

	move	$a0	$s0
	move	$a1	$s1
	move	$a2	$s4
	move	$a3	$s5

	# On calcule l'adresse de la case d'entrée dans le tableau
	jal	Calculer_Adresse_Case
	move	$a0	$v0		# $a0 : adresse de la case
	li	$a1	5				# $a1 : bit de poids 5 (sortie du labyrinthe)

	# On marque la case comme étant la sortie
	jal	Activer_Bit

	# On renvoie les coordonnées de l'entrée
	move	$v0	$s2		# $v0 : colonne de l'entrée
	move	$v1	$s3		# $v1 : ligne de l'entrée

# Epilogue
	lw	$ra	0($sp)
	lw	$s0	4($sp)
	lw	$s1	8($sp)
	lw	$s2	12($sp)
	lw	$s3	16($sp)
	lw	$s4	20($sp)
	lw	$s5	24($sp)
	addu	$sp	$sp	28
	jr	$ra




# Trouve la case d'entrée du labyrinthe
# Paramètres :
	# $a0	= Adresse du tableau
	# $a1	= Taille du tableau
# Renvoie :
	# $v0	= Coordonnée x de la case d'entrée
	# $v1 = Coordonnée y de la case d'entrée
Trouver_Entree:

# Prologue
	subu	$sp	$sp	24
	sw	$ra	($sp)
	sw	$s0	4($sp)		# $s0 : Adresse du tableau
	sw	$s1	8($sp)		# $s1 : Taille du tableau
	sw	$s2	12($sp)		# $s2 : Coordonnée x de l'entrée
	sw	$s3	16($sp)		# $s3 : Coordonnée y de l'entrée
	sw	$s4	20($sp)

# Corps de la fonction
	move	$s0	$a0		# #s0	: adresse du tableau
	move	$s1	$a1		# $s1	: taille du tableau

	li	$s2	0
	mulu	$s3	$a1	$a1
	Boucle_TrouverEntree:
		beq	$s2	$s3	FinBoucle_TrouverEntree

		# On vérifie que la case correspond à l'entrée
		addu	$a0	$s0	$s2
		li	$a1	4
		jal	Obtenir_Valeur_Bit
		addi	$s2	$s2	1
		# Si c'est pas le cas, on reviens dans la boucle
		beqz	$v0	Boucle_TrouverEntree

# Epilogue
	FinBoucle_TrouverEntree:
	# On soustrait 1 car on est allé trop loin dans le tableau
	subu	$s2	$s2	1
	# On divise le décalage par la taille du tableau pour obtenir les coordonnées
	div	$s2	$s1
	# On retourne les coordonnées de l'entrée
	mfhi	$v0
	mflo	$v1		# $v1 : coordonnée y de l'entrée

	lw	$ra	($sp)
	lw	$s0	4($sp)
	lw	$s1	8($sp)
	lw	$s2	12($sp)
	lw	$s3	16($sp)
	lw	$s4	20($sp)
	addu	$sp	$sp	24
	jr	$ra




# Génére la prochaine direction
# Paramètres :
	# $a0	= Adresse du tableau
	# $a1 = Taille du tableau
	# $a2	= Coordonnée x du tableau
	# $a3	= Coordonnée y du tableau
	# $t9	= Booléen mode résolution (1 si on est en mode résolution, 0 sinon)
# Renvoie :
	# $v0	= La prochaine direction
Generer_Prochaine_Direction:

# Prologue
	subu	$sp	$sp	36
	sw	$s0	0($sp)
	sw	$s1	4($sp)
	sw	$s2	8($sp)
	sw	$s3	12($sp)
	sw	$s4	16($sp)
	sw	$s5	20($sp)
	sw	$s6	24($sp)
	sw	$s7	28($sp)
	sw	$ra	32($sp)

# Corps de la fonction
	move	$s0	$a0		# $s0 : adresse de base
	move	$s1	$a1		# $s1 : taille du tableau
	move	$s2	$a2		# $s2 : coordonnée x de base
	move	$s3	$a3		# $s3 : coordonnée y de base
	li 	$s4 0 			# $s4 : compteur de 0 à 3 utilisé pour la génération de nombres aléatoires
	li	$s5	-1			# $s5 : direction à renvoyer
	li	$s6	0				# $s6 : direction actuelle
	move	$s7	$t9		# $s7 : booléen mode résolution (1 si on est en mode résolution, 0 sinon)

	# On fais une boucle sur les 4 directions
	Boucle_GenererProchaineCase:
		# On déplace les coordonnées dans la direction actuelle
		move	$a0	$s2		# $a0 : coordonnée x de base
		move	$a1	$s3		# $a1 : coordonnée y de base
		move	$a2	$s6		#	$a2 : direction actuelle
		jal	Deplacement_Case

		# On zappe si la case est en dehors des limites
		move	$a0	$s0 	# $a0 : adresse de base
		move	$a1	$s1		# $a1 : taille du tableau
		move	$a2	$v0		# $a2 :	coordonnée x de la case après déplacement
		move	$a3	$v1		# $a3	: coordonnée y de la case après déplacement
		jal	Hors_De_Limites
		bnez	$v0	ContinueBoucle_GenererProchaineCase
		jal	Calculer_Adresse_Case
		move	$a0	$v0

		# On zappe si la case a déjà été visitée
		li	$a1	7
		jal	Obtenir_Valeur_Bit
		bnez	$v0	ContinueBoucle_GenererProchaineCase

		# On zappe, si on est en mode résolution
		beqz	$s7	SansMur_GenererProchaineCase

			# On récupère l'adresse de la case actuelle
			move	$a0	$s0		# $a0 : adresse de base
			move	$a1	$s1		# $a1 : taille du tableau
			move	$a2	$s2		# $a2 : coordonnée x de base
			move	$a3	$s3		# $a3 : coordonnée y de base
			jal	Calculer_Adresse_Case

			# On vérifie la présence de murs dans le chemin
			move	$a0	$v0		# $a1 : adresse de la case
			move	$a1	$s6		# $a1 : direction actuelle
			jal	Obtenir_Valeur_Bit

			# On zappe s'il y a un mur
			bnez	$v0	ContinueBoucle_GenererProchaineCase

		SansMur_GenererProchaineCase:
		# On se déplace dans cette case
		# On génére un nombre aléatoire entre 0 et le nombre de voisins valides déjà trouvés
		li	$a0	0
		move	$a1	$s4 	# $a1 : compteur de 0 à 3
		jal	Nombre_Aleatoire_Entre_Deux_Bornes
		addi	$s4	$s4	1

		# Si le nombre aléatoire est différent de 0 alors on continue
		bnez	$v0	ContinueBoucle_GenererProchaineCase

		# Sinon, on considère cette direction valide
		# On stocke la direction
		move	$s5	$s6		# $s5 : direction actuelle à renvoyer

		ContinueBoucle_GenererProchaineCase:
		# On ajoute 1 à la direction actuelle et on fais une boucle
		addi	$s6	$s6	1
		blt	$s6	4	Boucle_GenererProchaineCase

	# On renvoie la direction selectionné
	move	$v0	$s5		# $s5 : direction à renvoyer

# Epilogue
	move	$a0	$s0
	move	$a1	$s1
	move	$a2	$s2
	move	$a3	$s3

	lw	$s0	0($sp)
	lw	$s1	4($sp)
	lw	$s2	8($sp)
	lw	$s3	12($sp)
	lw	$s4	16($sp)
	lw	$s5	20($sp)
	lw	$s6	24($sp)
	lw	$s7	28($sp)
	lw	$ra	32($sp)
	addu	$sp	$sp	36
	jr	$ra




# Indique si une case est en dehors des limites
# Paramètres :
	# $a1 =	Taille du tableau
	# $a2	= Coordonnée x
	# $a3	= Coordonnée y
# Renvoie :
	# $v0	= Booléen
Hors_De_Limites:

	bltz	$a2	Booleen_Vrai
	bge	$a2	$a1	Booleen_Vrai
	bltz	$a3	Booleen_Vrai
	bge	$a3	$a1	Booleen_Vrai
	j Booleen_Faux

	Booleen_Vrai:
		li	$v0	1
		jr	$ra

	Booleen_Faux:
		li	$v0	0
		jr	$ra




# Change de case pour se déplacer dans une direction
# Paramètres :
	# $a0	= Coordonnée x de la case
	# $a1	= Coordonnée y de la case
	# $a2	= La direction (0 = haut, 1 = droite, 2 = bas, 3 = gauche)
# Renvoie :
	# $v0 =	Coordonnée x de la case après déplacement
	# $v1	= Coordonnée y de la case après déplacement
Deplacement_Case:

	Deplacement_Haut:
	# Si la direction est 0 (haut), on soustrait 1 au coordonnée y de la case
	bne	$a2	0	Deplacement_Droite
	move	$v0	$a0
	subi	$v1	$a1	1
	jr	$ra

	# Si la direction est 1 (droite), on ajoute 1 au coordonnée x de la case
	Deplacement_Droite:
	bne	$a2	1	Deplacement_Bas
	addi	$v0	$a0	1
	move	$v1	$a1
	jr	$ra

	# Si la direction est 2 (bas), on ajoute 1 au coordonnée y de la case
	Deplacement_Bas:
	bne	$a2	2	Deplacement_Gauche
	move	$v0	$a0
	addi	$v1	$a1	1
	jr	$ra

	# Si la direction est 3 (gauche), on soustrait 1 au coordonnée x de la case
	Deplacement_Gauche:
	subi	$v0	$a0	1
	move	$v1	$a1
	jr	$ra




# Enregistre un entier à l'adresse donnée avec zero et de l'espace pour la suite de l'enregistrement de fichier
# Paramètres :
	# $a0	= L'entier à enregistrer
	# $a1	= L'adresse où enregistrer le char
Enregistrer_Nombre:

	li	$t1	10
	div	$a0	$t1
	mflo	$t0
	mfhi	$t1
	addu	$t0	$t0	48
	addu	$t1	$t1	48
	sb	$t0	($a1)
	sb	$t1	1($a1)
	li	$t0	32
	sb	$t0	2($a1)
	jr	$ra




# Ajoute l'extension "txt" à une chaine de caractères
# Paramètres :
	# $a0	= Adresse de la chaine de caractères
	# $a1	= Longueur de la chaine de caractères
Ajouter_Extension_Txt:

	la	$t1	TxtExtensionTxt
	addu	$t2	$a0	$a1

	# Boucle pour l'ajout de l'extension à la chaine de caractères
	Boucle_AjouterSuffixTxt:
		# On récupere les lettres de l'extension
		lb	$t3	($t1)
		sb	$t3	($t2)
		# On les ajoute à la fin de la chaine de caractères
		addi	$t1	$t1	1
		addi	$t2	$t2	1
		bne	$t3	0	Boucle_AjouterSuffixTxt

	jr	$ra




# Ajoute l'extension "resolu" à une chaine de caractères
# Paramètres :
	# $a0	= Adresse de la chaine de caractères
	# $a1	= Longueur de la chaine de caractères
Ajouter_Extension_Resolu:

	la	$t1	TxtExtensionResolu
	addu	$t2	$a0	$a1

	# Boucle pour l'ajout de l'extension à la chaine de caractères
	Boucle_AjouterSuffixResolu:
		# On récupere les lettres de l'extension
		lb	$t3	($t1)
		sb	$t3	($t2)
		# On les ajoute à la fin de la chaine de caractères
		addi	$t1	$t1	1
		addi	$t2	$t2	1
		bne	$t3	0	Boucle_AjouterSuffixResolu

	jr	$ra




# Enregistre le labyrinthe dans un fichier avec le descripteur de fichier
# Paramètres :
	# $a0 =	Adresse du tableau
	# $a1	= Taille du tableau
	# $a2	= Le descripteur de fichier pour enregistrer
Enregistrer_Fichier:

	subu	$sp	$sp	32
	sw	$ra	($sp)
	sw	$s0	4($sp)		# $s0 : adresse du tableau
	sw	$s1	8($sp)		# $s1 : taille du tableau
	sw	$s2	12($sp)		# $s2 : descripteur de fichier
	sw	$s3	16($sp)		# $s3 : ligne actuelle
	sw	$s4	20($sp)		# $s4 : case actuelle
	sw	$s5	24($sp)		# $s5 : adresse de la mémoire tampon actuelle
	sw	$s6	28($sp)		# $s6 : adresse de la mémoire tampon de base

	move	$s0	$a0		# $s0 : adresse du tableau
	move	$s1	$a1		# $s1 : taille du tableau
	move	$s2	$a2		# $s2 : descripteur de fichier pour enregistrer
	li	$s3	0

	# On calcule l'espace nécessaire pour la mémoire tampon
	mulu	$a0	$s1	$s1
	mulu	$a0	$a0	3
	addu	$a0	$a0	3

	# On alloue la mémoire tampon
	li	$v0	9
	syscall # Appel système : allocate heap memory

	move	$s5	$v0		# $s5 : adresse de la mémoire tampon
	move	$s6	$v0

	move	$a0	$s1		# $a0 : taille du tableau
	move	$a1	$s5		# $a1 : adresse de la mémoire tampon
	jal	Enregistrer_Nombre
	addi	$s5	$s5	3
	lb	$t0	TxtNouveauLigne

	# On remplace le dernier char dans la mémoire tampon par un \n pour changer de ligne
	sb	$t0	-1($s5)

	BoucleLigne_EnregistrerFichier:
		li	$s4	0
		BoucleCase_EnregistrerFichier:
			lb	$a0	($s0)
			move	$a1	$s5		# $a1 : adresse de la mémoire tampon
			jal	Enregistrer_Nombre
			# On se déplace dans le tableau de 1 char
			addi	$s0	$s0	1
			# On se déplace dans la mémoire tampon de 3 chars
			addi	$s5	$s5	3
			# On incrémente le numéro de la case
			addi	$s4	$s4	1
			# On fais une boucle jusqu'à enregistrer tout le tableau de cases
			bne	$s4	$s1	BoucleCase_EnregistrerFichier

		lb	$t0	TxtNouveauLigne
		# On remplace le dernier char dans la mémoire tampon par un \n pour changer de ligne
		sb	$t0	-1($s5)
		# On incrémente le numéro de la ligne
		addi	$s3	$s3	1
		bne	$s3	$s1	BoucleLigne_EnregistrerFichier

	li	$v0	15
	move	$a0	$s2		# $a0 : descripteur de fichier pour enregistrer
	move	$a1	$s6		# $a1 : adresse de la mémoire tampon de base

	# On calcule la taille de la mémoire tampon
	subu	$a2	$s5	$s6
	syscall # Appel système : write to file

	# On ferme le descripteur de fichier
	li	$v0	16
	move	$a0	$s2
	syscall # Appel système : close file

	lw	$ra	($sp)
	lw	$s0	4($sp)
	lw	$s1	8($sp)
	lw	$s2	12($sp)
	lw	$s3	16($sp)
	lw	$s4	20($sp)
	lw	$s5	24($sp)
	lw	$s6	28($sp)
	addu	$sp	$sp	32
	jr	$ra




# Vérifie si un certain bit dans l'octet vaut 1 ou 0
# Paramètres :
	# $a0	= Adresse de la case
	# $a1	= Le bit à vérifier (0 = le bit le plus petit, 8 = le plus fort)
# Renvoie :
	# $v0	= 0 si le bit est absent, 1 sinon
Obtenir_Valeur_Bit:

	lbu	$t0	($a0)
	li	$v0	1
	sllv	$v0	$v0	$a1	# $v1: 1 << $a1
	and	$v0	$v0	$t0
	jr	$ra




# Active un certain bit dans l'octet (le met à 1)
# Paramètres :
	# $a0	= Adresse de la case
	# $a1	= Le bit à changer
	# (0 = bit avec le poids le plus petit, 8 = le plus fort)
Activer_Bit:

	lbu	$t0	($a0)			# $t0 = adresse de la case
	li	$t1	1
	sllv	$t1	$t1	$a1	# $t1 = 1 << N

	# On met le bit à 1 et on l'enregistre
	or	$t0	$t0	$t1
	sb	$t0	($a0)

	jr	$ra




# Désactive un certain bit dans l'octet (le met à 0)
# Paramètres :
	# $a0	= Adresse de la case
	# $a1	= Le bit à changer
	# (0 = bit avec le poids le plus petit, 8 = le plus fort)
Desactiver_Bit:

	lbu	$t0	($a0)		# $t0 = adresse de la case
	li	$t1	1
	sllv	$t1	$t1	$a1

	# On met le bit à 0 et on l'enregistre
	not	$t1	$t1
	and	$t0	$t0	$t1
	sb	$t0	($a0)

	jr	$ra




# Désactive tout les bits avec un certains poids (les met à 0)
# Paramètres :
	# $a0	= Adresse du tableau
	# $a1	= Taille du tableau
	# $a2	= Le bit à changer
	# (0 = bit avec le poids le plus petit, 8 = le plus fort)
Desactiver_Tout_Bits:

	subu	$sp	$sp	8
	sw	$ra	($sp)
	sw	$s0	4($sp)

	mul	$s0	$a1	$a1
	addu	$s0	$s0	$a0
	move	$a1	$a2

	Boucle_DesactiverBits:
		jal	Desactiver_Bit
		addu	$a0	$a0	1
		bne	$a0	$s0	Boucle_DesactiverBits

	lw	$ra	($sp)
	lw	$s0	4($sp)
	addu	$sp	$sp	8



# Retourne vers la fonction appelante (utiliser avec des branchements)
Sauter_Registre:
	jr	$ra


# Fini le programme
Exit:
	li	$v0	10
	syscall # Appel système : terminate execution
