delimiter $$

CREATE TABLE `dg_players` (
  `player_id` int(11) NOT NULL AUTO_INCREMENT,
  `Steam_ID` varchar(50) NOT NULL,
  `last_recorded_name` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `drinks` int(11) NOT NULL DEFAULT '0',
  `drinks_dcg` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`player_id`),
  UNIQUE KEY `player_id_UNIQUE` (`player_id`),
  UNIQUE KEY `Steam_ID_UNIQUE` (`Steam_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2220 DEFAULT CHARSET=latin1$$


delimiter $$

CREATE TABLE `dg_assister_drinks` (
  `player_id` int(11) NOT NULL,
  `drink_count` int(11) NOT NULL DEFAULT '0',
  `killed_count` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`player_id`),
  KEY `fk_player_assister` (`player_id`),
  CONSTRAINT `fk_player_assister` FOREIGN KEY (`player_id`) REFERENCES `dg_players` (`player_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1$$

delimiter $$

CREATE TABLE `dg_weapon_drinks` (
  `player_id` int(11) NOT NULL,
  `weapon` varchar(45) NOT NULL,
  `drink_count` int(11) NOT NULL DEFAULT '0',
  `killed_count` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`player_id`,`weapon`),
  KEY `fk_player` (`player_id`),
  CONSTRAINT `fk_player_weapons` FOREIGN KEY (`player_id`) REFERENCES `dg_players` (`player_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1$$

delimiter $$

CREATE TABLE `dgwepmults` (
  `weapon` varchar(45) NOT NULL,
  `mult` int(11) NOT NULL DEFAULT '2',
  PRIMARY KEY (`weapon`),
  UNIQUE KEY `weapon_UNIQUE` (`weapon`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1$$

delimiter $$

CREATE TABLE `dgtaunts` (
  `Steam_ID` varchar(50) NOT NULL,
  `Taunt` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`Steam_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1$$

delimiter $$

CREATE PROCEDURE `add_drinks`(
IN attack_name VARCHAR(50) CHARACTER SET utf8,
IN attack_steam_id VARCHAR(50),
IN assist_name VARCHAR(50) CHARACTER SET utf8,
IN assist_steam_id VARCHAR(50),
IN victim_name VARCHAR(50) CHARACTER SET utf8,
IN victim_steam_id VARCHAR(50),
IN kill_weapon VARCHAR(45),
IN attack_drinks INT(11),
IN assist_drinks INT(11),
IN victim_drinks INT(11)
)
BEGIN

DECLARE at_id int default -1;
DECLARE as_id int default -1;
DECLARE vic_id int default -1;
DECLARE dcg int DEFAULT 0;

#If there was an attacker
IF attack_steam_id IS NOT NULL AND CHAR_LENGTH(attack_steam_id) > 0 THEN
    #See if you can't find an id for this person
    SELECT player_id INTO at_id FROM dg_players WHERE Steam_ID = attack_steam_id;
    #If you cant add them
    IF at_id = -1 THEN
        INSERT INTO dg_players (Steam_ID, last_recorded_name) VALUES (attack_steam_id, attack_name);
        SET at_id = LAST_INSERT_ID();
    ELSE
        #Update their name
        UPDATE dg_players SET last_recorded_name = attack_name where player_id = at_id;
    END IF;

    #Insert or update the respective values
    UPDATE dg_weapon_drinks SET drink_count = drink_count + attack_drinks, killed_count = killed_count +1
        WHERE player_id = at_id AND weapon = kill_weapon;
        
    #Then update didn't happen
    IF ROW_COUNT() < 1 THEN
        INSERT INTO dg_weapon_drinks (player_id, weapon, drink_count, killed_count)
            VALUES(at_id, kill_weapon, attack_drinks, 1);
    END IF;

END IF;

#Same as before but with the assister 
IF assist_steam_id IS NOT NULL AND CHAR_LENGTH(assist_steam_id) > 0 THEN
    SELECT player_id INTO as_id FROM dg_players WHERE Steam_ID = assist_steam_id;
    IF as_id = -1 THEN
        INSERT INTO dg_players (Steam_ID, last_recorded_name) VALUES (assist_steam_id, assist_name);
        SET as_id = LAST_INSERT_ID();
    ELSE
        #Update their name
        UPDATE dg_players SET last_recorded_name = assist_name where player_id = as_id;
    END IF;
    
    UPDATE dg_assister_drinks SET drink_count = drink_count + assist_drinks, killed_count = killed_count +1
        WHERE player_id = as_id;
    
    IF ROW_COUNT() < 1 THEN
        INSERT INTO dg_assister_drinks (player_id, drink_count, killed_count)
            VALUES(as_id, assist_drinks, 1);
    END IF;

END IF;

#if no attacker or assister then its a dcg drink
IF at_id = -1 and as_id = -1 THEN
    SET dcg = victim_drinks;
    SET victim_drinks = 0;
END IF;

#Update the victims values in the dg_players table

SELECT player_id INTO vic_id from dg_players WHERE Steam_ID = victim_steam_id;

IF vic_id = -1 THEN
    INSERT INTO dg_players (Steam_ID, last_recorded_name, drinks, drinks_dcg)
        VALUES (victim_steam_id, victim_name, victim_drinks, dcg);
ELSE
    UPDATE dg_players SET last_recorded_name = victim_name, drinks = drinks + victim_drinks, drinks_dcg = drinks_dcg + dcg
        WHERE player_id = vic_id;
END IF;

END$$

INSERT INTO `dgwepmults` VALUES ('amputator',2),('axtinguisher',2),('back_scratcher',2),('ball',6),('bat',2),('battleaxe',2),('battleneedle',2),('bat_wood',2),('bleed_kill',3),('bonesaw',2),('boston_basher',2),('bottle',2),('bushwacka',2),('candy_cane',2),('claidheamohmor',2),('club',2),('deflect_arrow',10),('deflect_rocket',4),('demokatana',2),('demoshield',3),('disciplinary_action',2),('eternal_reward',2),('eviction_notice',2),('fireaxe',2),('fists',2),('fryingpan',2),('gloves',2),('gloves_running_urgently',2),('headtaker',2),('holiday_punch',2),('holy_mackerel',4),('knife',2),('lava_axe',2),('lava_bat',2),('mailbox',2),('market_gardner',3),('nonnonviolent_protest',3),('paintrain',2),('persian_persuader',2),('pickaxe',2),('powerjack',3),('robot_arm',2),('robot_arm_combo_kill',2),('robot_arm_kill',2),('sandman',2),('shahanshah',2),('sharp_dresser',2),('shovel',2),('sledgehammer',2),('solemn_vow',2),('southern_comfort_kill',2),('southern_hospitality',2),('splendid_screen',3),('spy_cicle',2),('steel_fists',2),('sword',2),('the_maul',2),('thirddegree',2),('tribalkukri',2),('ubersaw',2),('ullapool_caber',3),('ullapool_caber_explosion',2),('warfan',20),('warrior_spirit',2),('world',1),('wrap_assassin',10),('wrench',2),('wrench_jag',2);