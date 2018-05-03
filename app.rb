class App < Sinatra::Base
	enable :sessions

	get ('/') do
		db = SQLite3::Database.new("db/db.db")
		slim(:index, locals:{msg: session[:msg]})
	end
	post ('/register' ) do
		db = SQLite3::Database.new("db/db.db")
		username = params[:username]
		password = BCrypt::Password.create( params[:password] )
		password2 = BCrypt::Password.create( params[:password2] )
		
		if username == "" || password == "" || password == ""
			session[:msg] = "Please enter a username and password."
		elsif params[:password] != params[:password2]
			session[:msg] = "Passwords don't match"
		elsif db.execute("SELECT user FROM user_data WHERE user=?", username) != []
			session[:msg] = "Username already exists"
		else
			db.execute("INSERT INTO user_data ('user', 'password') VALUES (?,?)", [username, password])
		end
		redirect('/')
	end
	post('/login') do
		db = SQLite3::Database.new("db/db.db")
		username = params[:username]
		password = params[:password]
		if username == "" || password == ""
			session[:msg] = "Please enter a username and a password."
			redirect('/')
		else
			db_password = db.execute("SELECT password FROM user_data WHERE user=?", username)
			if db_password == []
				session[:msg] = "Username doesn't exist"
				redirect('/')
			else
				db_password = db_password[0][0]
				password_digest =  db_password
				password_digest = BCrypt::Password.new( password_digest )

				if password_digest == password
					user_id = db.execute("SELECT id FROM user_data WHERE user=?", username)
					user_id = user_id[0][0]
					session[:user_id] = user_id
					redirect('/user')
				else
					session[:user_id] = nil
					session[:msg] = "Wrong password or username"
					redirect('/')
				end
			end
		end
	end
	get('/user') do
		db = SQLite3::Database.new("db/db.db")
		if session[:user_id]
			username = db.execute("SELECT user FROM user_data WHERE id=?", session[:user_id])
			notes = db.execute("SELECT content, id FROM notes WHERE user_id=?", session[:user_id])
			slim(:user, locals:{notes: notes, username:username})
		else 
			session[:msg] = "Login or register to access this page."
			redirect('/')
		end
	end

	get('/main') do
		db = SQLite3::Database.new("db/db.db")
		if session[:user_id]
			username = db.execute("SELECT user FROM user_data WHERE id=?", session[:user_id])
			notes = db.execute("SELECT content id FROM notes WHERE user_id=?", session[:user_id])
			slim(:mainsite, locals:{notes: notes, username:username})
		else 
			session[:msg] = "Login or register to access this page."
			redirect('/')
		end
	end
	post("/add_note") do
		db = SQLite3::Database.new("db/db.db")
		db.execute("INSERT INTO notes(user_id, content) VALUES(?,?)", [session[:user_id], params[:content]] )
		redirect("/user")
	end
	post('/delete_note') do
		db = SQLite3::Database.new('db/db.db')
		db.execute("DELETE FROM notes WHERE id=?", params[:id])
		redirect('/user')
	end
	get('/logout') do
		session[:user_id] = nil
		redirect("/")
	end
end           
