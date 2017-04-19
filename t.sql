
# Tree File System with Element Order in a table
# no escaping performed. Undefined behaviour on invalid input.
# tNew(p); tDelete(p); tList(p); tMove(p,t); tSet(p,d); tGet(p); tUp(p); tDown(p);

create database reg default character set utf8;

use reg;

create table `t` (
	`path`	varchar(240) not null default '',
	`name`	varchar(60) not null default '',
	`pos`	int not null default 0,
	`data`	text,
	index i (`path`,`name`),
	unique u (`path`,`name`)
);

delimiter //

create procedure tNew ( p varchar(300) ) f:
begin

	declare cpath varchar(240) default '';
	declare cname varchar(60) default '';
	declare cchar varchar(2);
	declare cpathlevel, i int default 0;
	
	if length( p ) = 0 then leave f; end if;
	
	set p = trim( both '/' from p );
	
	if locate( '/', p ) = 0 then
			insert into `t` (`path`, `name`, `pos`) 
				select '', p, max(`pos`)+1 from `t` where `path` = '';
	else
		while i < char_length( p ) do
			set i = i + 1;
			set cchar = substring( p, i, 1 );
			if cchar = '/' then
				if not exists ( select `path` from `t` where `path` = cpath and `name` = cname ) then
					insert into `t` (`path`, `name`, `pos`)
						select cpath, cname, max(`pos`)+1 from `t` where `path` = cpath;
				end if;
				if cpathlevel = 0 then 
					set cpath = cname;
				else
					set cpath = concat( cpath, '/', cname );
				end if;
				set cpathlevel = cpathlevel + 1;
				set cname = '';
			else
				set cname = concat( cname, cchar );
			end if;
		end while;
		if not exists ( select `path` from `t` where `path` = cpath and `name` = cname ) then
			insert into `t` (`path`, `name`, `pos`)
				select cpath, cname, max(`pos`)+1 from `t` where `path` = cpath;
		end if;
	end if;
end

//

create procedure tDelete( p varchar(300) ) f:
begin
	declare cpath varchar(240) default '';
	declare cname varchar(60) default '';
	declare cpos int default 0;
	
	if length( p ) = 0 then leave f; end if;
	
	if not exists(	
	select `path`,`name`,`pos` into cpath, cname, cpos from `t` where
		trim( leading '/' from concat( `path`,'/', `name` ) ) = p
	) then leave f; end if;

	delete from `t` where
		`path` = p
		or `path` like concat( p, '/%' )
		or trim( leading '/' from concat( `path`,'/', `name` ) ) = p;
		
	update `t` set `pos` = `pos`-1 where
		`path` = cpath
		and `pos` > cpos;
end

//

create procedure tUp( p varchar(300) )
begin
	declare cpos int default 0;
	declare cpath varchar(240) default '';
	
	select `path`, `pos` into cpath, cpos from `t` where
		trim( leading '/' from concat(`path`,'/', `name`) ) = p;

	if cpos > 0 then
		update `t` set `pos` = cpos where `pos` = cpos-1
			and `path` = cpath;
		update `t` set `pos` = cpos-1 where
			trim( leading '/' from concat(`path`, '/', `name`) ) = p;
	end if;
end

//

create procedure tDown( p varchar(300) )
begin
	declare cpos int default 0;
	declare cpath varchar(240) default '';
	declare maxpos int default 0;
	
	select `path`, `pos` into cpath, cpos from `t` where
		trim( leading '/' from concat(`path`,'/', `name`) ) = p;
	
	select max(`pos`) into maxpos from `t` where `path` = cpath;
	
	if cpos < maxpos then
		update `t` set `pos` = cpos where `pos` = cpos+1
			and `path` = cpath;
		update `t` set `pos` = cpos+1 where
			trim( leading '/' from concat(`path`, '/', `name`) ) = p;
	end if;
end

//

create procedure tMove( p varchar(300), t varchar(240) )
begin
	declare cpath varchar(240) default '';
	declare cname varchar(60) default '';
	declare cpos, newpos int default 0;
	
	select `path`,`name`,`pos` into cpath, cname, cpos from `t` where
		trim( leading '/' from concat( `path`,'/', `name` ) ) = p;

	select max(`pos`)+1 into newpos from `t` where `path` = t;
	
	update `t` set `path` = t, `pos` = newpos where
		`path` = cpath
		and `name` = cname;
	
	update `t` set `path` = trim( leading '/' from concat( t, '/', cname ) ) where
		`path` = p;
		
	update `t` set `path` =
		trim( leading '/' from concat( t, '/', cname, '/', substring( `path`, length(p)+2 ) ) ) where
			`path` like concat( p, '/%' );
end

//

create procedure tList( p varchar(300) )
begin
	select `name` from `t`
	where `path` = p
	order by `pos` asc;
end

//

create procedure tSet( p varchar(300), d text )
begin
	update `t` set `data` = d where
		trim( leading '/' from concat( `path`,'/', `name` ) ) = p;
end

//

create procedure tGet( p varchar(300) )
begin
	select `data` from `t` where 
		trim( leading '/' from concat( `path`,'/', `name` ) ) = p;
end

//

delimiter ;