CREATE TABLE `playermenuv2_animations` (
  `id` int(11) NOT NULL,
  `identifier` varchar(46) DEFAULT NULL,
  `label` varchar(100) NOT NULL,
  `anim` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


ALTER TABLE `playermenuv2_animations`
  ADD PRIMARY KEY (`id`);


ALTER TABLE `playermenuv2_animations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
;

ALTER TABLE `users`
	ADD COLUMN `playtime` bigint(255) DEFAULT NULL;

	
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES

('gps', 'GPS', 1, 0, 1),
('ropes', 'Ropes', 1, 0, 1),
('headbag', 'Headbag', 1, 0, 1);