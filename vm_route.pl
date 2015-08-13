#!/usr/bin/perl

use Dancer;
use DBI;
use File::Spec;
use File::Slurp;
use Template;
 
set 'database'     => 'database';
set 'session'      => 'Simple';
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;
set 'username'     => 'admin';
set 'password'     => 'password';
set 'layout'       => 'main';

my $flash;
 
sub set_flash {
       my $message = shift;
 
       $flash = $message;
}
 
sub get_flash {
 
       my $msg = $flash;
       $flash = "";
 
       return $msg;
}
 
sub connect_db {
       my $dbh = DBI->connect("dbi:SQLite:dbname=".setting('database')) or
               die $DBI::errstr;
 
       return $dbh;
}
 
sub init_db {
       my $db = connect_db();
       my $schema = read_file('./schema.sql');
       $db->do($schema) or die $db->errstr;
}
 
hook before_template => sub {
       my $tokens = shift;
        
	   $tokens->{'css_url'} = request->base . 'css/style.css';
       $tokens->{'login_url'} = uri_for('/login');
       $tokens->{'logout_url'} = uri_for('/logout');
};
 
get '/' => sub {
	send_file 'index.html';
};

get '/canvas' => sub { 
	send_file 'canvas.html';
};

get '/json' => sub {
	send_file 'data_out.json';
};

 
post '/add' => sub {
       if ( not session('logged_in') ) {
               send_error("Not logged in", 401);
       }
 
       my $db = connect_db();
       my $sql = 'insert into entries (title, text) values (?, ?)';
       my $sth = $db->prepare($sql) or die $db->errstr;
       $sth->execute(params->{'title'}, params->{'text'}) or die $sth->errstr;
 
       set_flash('New entry posted!');
       redirect '/';

};

post '/edit' => sub {
	if ( not session('logged_in') ) {
		send_error("Not logged in", 401);
	}
	
	my $db = connect_db();
	my $sql = 'update entries set text = ? where title = ?';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute(params->{'text'}, params-> {'title'}) or die $sth->errstr;

	set_flash('Entry modified!');
	redirect '/';


};

post '/remove' => sub {
	if (not session('logged_in') ) {
			send_error("Not logged in", 401);
	}
	
	my $db = connect_db();
	my $sql = 'delete from entries WHERE title=(?)';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute(params->{'title'}) or die $sth->errstr;

	set_flash('Entry deleted!');
	redirect '/';

};
 
post '/login' => sub {
	my $err;
	my $db = connect_db();
	my $username = params->{'username'};
	my $password = params->{'password'};
	my $rows = $db->selectrow_array("SELECT COUNT(*) FROM login WHERE username='$username' AND password='$password'", undef);
	if ($rows < 1){
		set_flash('Invalid username/password.');
		send_error('Invalid username/password');
	}
	else{
		set_flash("Welcome, $username.");
		session 'logged_in' => true;
	}

};

post '/register' => sub {
	my $err;
	my $db = connect_db();
	my $username = params->{'new_username'};
	my $password = params->{'new_password'};
	my $sql = 'INSERT INTO login (username,password) VALUES (?,?)';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute(params->{'new_username'}, params->{'new_password'}) or die $sth->errstr;

	set_flash('New User Added!');
};
 
get '/logout' => sub {
       session->destroy;
       set_flash('You are logged out.');
       redirect '/logout_page';
};

get '/logout_page' => sub {
	send_file 'logout.html';
};
 
init_db();
start;

