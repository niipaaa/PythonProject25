import paramiko


# PASSWORD = ""

PRIVATE_KEY_PATH = r""
SETUP_SCRIPT_PATH = "setup.sh"
REMOTE_SCRIPT_PATH = "/root/setup.sh"


# def connect_password():
#     client = paramiko.SSHClient()
#     client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
#     client.connect(HOST, PORT, USERNAME, PASSWORD)
#     return client


def connect_ssh(host, user):
    key = paramiko.RSAKey.from_private_key_file(PRIVATE_KEY_PATH)
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(host, 22, user, pkey=key, timeout=5)
    return client


def upload_script(client):
    sftp = client.open_sftp()
    sftp.put(SETUP_SCRIPT_PATH, REMOTE_SCRIPT_PATH)
    sftp.close()


def run_script(client):
    client.exec_command(f"chmod +x {REMOTE_SCRIPT_PATH}")
    stdin, stdout, stderr = client.exec_command(f"bash {REMOTE_SCRIPT_PATH}")

    for line in iter(stdout.readline, ""):
        print(line.strip())

    err = stderr.read().decode()
    if err:
        print("❌ERROR:")
        print(err)


if __name__ == "__main__":
    client = connect_ssh("", "root")
    upload_script(client)
    run_script(client)
    client.close()
