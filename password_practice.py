from werkzeug.security import generate_password_hash, check_password_hash

password = input("Enter a password: ")

hashed_password = generate_password_hash(password)
print(hashed_password)
entered_password = input("Enter password again: ")

if check_password_hash(hashed_password, entered_password):
    print("Password Verified!")
else:
    print("Incorrect Password!")
