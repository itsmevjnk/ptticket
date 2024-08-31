PREPARE insert_product(int, varchar(24), int) AS INSERT INTO "static"."Products" VALUES ($1, $2, $3);

EXECUTE insert_product(0, 'None', 0);
EXECUTE insert_product(1, 'Zone 1+2', 3);
EXECUTE insert_product(2, 'Zone 1+2+3', 7);
EXECUTE insert_product(3, 'Zone 1/2 overlap', 0);
EXECUTE insert_product(4, 'Zones 1-15', 32767);
EXECUTE insert_product(5, 'Zone 2', 2);
EXECUTE insert_product(6, 'Zone 3', 4);
EXECUTE insert_product(7, 'Zone 4', 8);
EXECUTE insert_product(8, 'Zone 5', 16);
EXECUTE insert_product(9, 'Zone 6', 32);
EXECUTE insert_product(10, 'Zone 7', 64);
EXECUTE insert_product(11, 'Zone 8', 128);
EXECUTE insert_product(12, 'Zone 9', 256);
EXECUTE insert_product(13, 'Zone 10', 512);
EXECUTE insert_product(14, 'Zone 11', 1024);
EXECUTE insert_product(15, 'Zone 12', 2048);
EXECUTE insert_product(16, 'Zone 13', 4096);
EXECUTE insert_product(17, 'Zone 14', 8192);
EXECUTE insert_product(18, 'Zone 15', 16384);
EXECUTE insert_product(19, 'Zones 2-3', 6);
EXECUTE insert_product(20, 'Zones 3-4', 12);
EXECUTE insert_product(21, 'Zones 4-5', 24);
EXECUTE insert_product(22, 'Zones 5-6', 48);
EXECUTE insert_product(23, 'Zones 6-7', 96);
EXECUTE insert_product(24, 'Zones 7-8', 192);
EXECUTE insert_product(25, 'Zones 8-9', 384);
EXECUTE insert_product(26, 'Zones 9-10', 768);
EXECUTE insert_product(27, 'Zones 10-11', 1536);
EXECUTE insert_product(28, 'Zones 11-12', 3072);
EXECUTE insert_product(29, 'Zones 12-13', 6144);
EXECUTE insert_product(30, 'Zones 13-14', 12288);
EXECUTE insert_product(31, 'Zones 14-15', 24576);
EXECUTE insert_product(32, 'Zones 2-4', 14);
EXECUTE insert_product(33, 'Zones 3-5', 28);
EXECUTE insert_product(34, 'Zones 4-6', 56);
EXECUTE insert_product(35, 'Zones 5-7', 112);
EXECUTE insert_product(36, 'Zones 6-8', 224);
EXECUTE insert_product(37, 'Zones 7-9', 448);
EXECUTE insert_product(38, 'Zones 8-10', 896);
EXECUTE insert_product(39, 'Zones 9-11', 1792);
EXECUTE insert_product(40, 'Zones 10-12', 3584);
EXECUTE insert_product(41, 'Zones 11-13', 7168);
EXECUTE insert_product(42, 'Zones 12-14', 14336);
EXECUTE insert_product(43, 'Zones 13-15', 28672);
EXECUTE insert_product(44, 'Zones 2-5', 30);
EXECUTE insert_product(45, 'Zones 3-6', 60);
EXECUTE insert_product(46, 'Zones 4-7', 120);
EXECUTE insert_product(47, 'Zones 5-8', 240);
EXECUTE insert_product(48, 'Zones 6-9', 480);
EXECUTE insert_product(49, 'Zones 7-10', 960);
EXECUTE insert_product(50, 'Zones 8-11', 1920);
EXECUTE insert_product(51, 'Zones 9-12', 3840);
EXECUTE insert_product(52, 'Zones 10-13', 7680);
EXECUTE insert_product(53, 'Zones 11-14', 15360);
EXECUTE insert_product(54, 'Zones 12-15', 30720);
EXECUTE insert_product(55, 'Zones 2-6', 62);
EXECUTE insert_product(56, 'Zones 3-7', 124);
EXECUTE insert_product(57, 'Zones 4-8', 248);
EXECUTE insert_product(58, 'Zones 5-9', 496);
EXECUTE insert_product(59, 'Zones 6-10', 992);
EXECUTE insert_product(60, 'Zones 7-11', 1984);
EXECUTE insert_product(61, 'Zones 8-12', 3968);
EXECUTE insert_product(62, 'Zones 9-13', 7936);
EXECUTE insert_product(63, 'Zones 10-14', 15872);
EXECUTE insert_product(64, 'Zones 11-15', 31744);
EXECUTE insert_product(65, 'Zones 2-7', 126);
EXECUTE insert_product(66, 'Zones 3-8', 252);
EXECUTE insert_product(67, 'Zones 4-9', 504);
EXECUTE insert_product(68, 'Zones 5-10', 1008);
EXECUTE insert_product(69, 'Zones 6-11', 2016);
EXECUTE insert_product(70, 'Zones 7-12', 4032);
EXECUTE insert_product(71, 'Zones 8-13', 8064);
EXECUTE insert_product(72, 'Zones 9-14', 16128);
EXECUTE insert_product(73, 'Zones 10-15', 32256);
EXECUTE insert_product(74, 'Zones 2-8', 254);
EXECUTE insert_product(75, 'Zones 3-9', 508);
EXECUTE insert_product(76, 'Zones 4-10', 1016);
EXECUTE insert_product(77, 'Zones 5-11', 2032);
EXECUTE insert_product(78, 'Zones 6-12', 4064);
EXECUTE insert_product(79, 'Zones 7-13', 8128);
EXECUTE insert_product(80, 'Zones 8-14', 16256);
EXECUTE insert_product(81, 'Zones 9-15', 32512);
EXECUTE insert_product(82, 'Zones 2-9', 510);
EXECUTE insert_product(83, 'Zones 3-10', 1020);
EXECUTE insert_product(84, 'Zones 4-11', 2040);
EXECUTE insert_product(85, 'Zones 5-12', 4080);
EXECUTE insert_product(86, 'Zones 6-13', 8160);
EXECUTE insert_product(87, 'Zones 7-14', 16320);
EXECUTE insert_product(88, 'Zones 8-15', 32640);
EXECUTE insert_product(89, 'Zones 2-10', 1022);
EXECUTE insert_product(90, 'Zones 3-11', 2044);
EXECUTE insert_product(91, 'Zones 4-12', 4088);
EXECUTE insert_product(92, 'Zones 5-13', 8176);
EXECUTE insert_product(93, 'Zones 6-14', 16352);
EXECUTE insert_product(94, 'Zones 7-15', 32704);
EXECUTE insert_product(95, 'Zones 2-11', 2046);
EXECUTE insert_product(96, 'Zones 3-12', 4092);
EXECUTE insert_product(97, 'Zones 4-13', 8184);
EXECUTE insert_product(98, 'Zones 5-14', 16368);
EXECUTE insert_product(99, 'Zones 6-15', 32736);
EXECUTE insert_product(100, 'Zones 2-12', 4094);
EXECUTE insert_product(101, 'Zones 3-13', 8188);
EXECUTE insert_product(102, 'Zones 4-14', 16376);
EXECUTE insert_product(103, 'Zones 5-15', 32752);
EXECUTE insert_product(104, 'Zones 2-13', 8190);
EXECUTE insert_product(105, 'Zones 3-14', 16380);
EXECUTE insert_product(106, 'Zones 4-15', 32760);
EXECUTE insert_product(107, 'Zones 2-14', 16382);
EXECUTE insert_product(108, 'Zones 3-15', 32764);
EXECUTE insert_product(109, 'Zones 2-15', 32766);
