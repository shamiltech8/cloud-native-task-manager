from werkzeug.security import generate_password_hash, check_password_hash

password = "shamil123"

hashed_password = generate_password_hash(password)

print("Stored Hash:")
print(hashed_password)

print("\nChecking Correct Password:")
print(check_password_hash(hashed_password, "shamil123"))

print("\nChecking Wrong Password:")
print(check_password_hash(hashed_password, "hello123"))
