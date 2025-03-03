import requests
import os
import sys
import subprocess
import urllib3
import json
import logging

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Настройка логирования. Патх менять на прод после аппрува 
logging.basicConfig(
    filename='C:\\Scripts for SCCM\\Automatic Update Software\\DBeaver\\Scripts\\dbeaver_update.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Настройка .json. Патх менять на прод после аппрува 
def load_app_settings():
    with open('C:\\Scripts for SCCM\\Automatic Update Software\\DBeaver\\Scripts\\appsettings.json') as f:
        return json.load(f)

def get_latest_dbeaver_version(api_url):
    try:
        response = requests.get(api_url, verify=False)
        response.raise_for_status()  
        data = response.json()

        latest_version = data["tag_name"]
        download_url = None

        for asset in data["assets"]:
            #Мона в теории менять на .msi, в зависимости от необходимости. 
            #Нид чендж: 
            #if "chetotam" in asset["name"].lower() and asset["name"].endswith(".msi"):
                #download_url = asset["browser_download_url"]
                #break
            if "dbeaver" in asset["name"].lower() and ".exe" in asset["name"].lower():
                download_url = asset["browser_download_url"]
                break

        return latest_version, download_url

    except requests.exceptions.RequestException as e:
        logging.error(f"Ошибка при запросе к API GitHub: {e}")
        return None, None

#Функция проверки наличия скачиваемой версии по патх. Патх: автоматикли в дефолт папке 
def download_dbeaver_installer(download_url, base_download_dir, version):
    download_dir = os.path.join(base_download_dir, version)

    if os.path.exists(download_dir):
        logging.warning(f"Папка {download_dir} уже существует. Скрипт остановлен.")
        sys.exit(1)

    os.makedirs(download_dir, exist_ok=True)

    filename = os.path.basename(download_url)
    download_path = os.path.join(download_dir, filename)

    try:
        logging.info(f"Скачивание {filename}...")
        response = requests.get(download_url, stream=True, verify=False)
        response.raise_for_status()

        with open(download_path, "wb") as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)

        logging.info(f"Файл успешно скачан: {download_path}")
        return download_path

    except requests.exceptions.RequestException as e:
        logging.error(f"Ошибка при скачивании файла: {e}")
        return None

def create_sccm_application_via_ps(app_name, version, download_path, ps_script_path, install_command):
    if not os.path.exists(ps_script_path):
        logging.error(f"Ошибка: файл PowerShell-скрипта не найден: {ps_script_path}")
        return

    version_without_v = version[1:] if version.startswith("v") else version
    localized_name = app_name.rsplit(" ", 1)[0] 
    msi_folder_path = os.path.dirname(download_path)
    filename = os.path.basename(download_path)

    #1 Type(Main):
    command = [
        "powershell",
        "-ExecutionPolicy", "Bypass",
        "-File", ps_script_path,
        "-AppName", app_name,
        "-AppVersion", version_without_v,
        "-MsiPath", msi_folder_path, 
        "-LocalizedName", localized_name,  
        "-InstallCommand", f"{filename} {install_command}"  
    ]

    #2 Type: 
    #command = [
    #    "powershell",
    #    "-File", ps_script_path,
    #    "-AppName", app_name,
    #    "-AppVersion", version_without_v,
    #    "-MsiPath", msi_folder_path, 
    #    "-LocalizedName", localized_name,  
    #    "-InstallCommand", f"{filename} {install_command}"  
    #]
    logging.info("Команда: %s", command)

    result = subprocess.run(command, capture_output=True, text=True, encoding='cp866')

    logging.info("Результат выполнения PowerShell-скрипта:")
    logging.info(result.stdout)
    if result.stderr:
        logging.error("Ошибки:")
        logging.error(result.stderr)

if __name__ == "__main__":
    config = load_app_settings()
    #Берёт из .json конфигурации
    latest_version, download_url = get_latest_dbeaver_version(config["api_url"])

    if latest_version and download_url:
        logging.info(f"Последняя версия DBeaver: {latest_version}")

        #Ченж на прод патх в .json после аппрува 
        download_path = download_dbeaver_installer(download_url, config["base_download_directory"], latest_version)
        if download_path:
            logging.info(f"Файл сохранен: {download_path}")

            app_name = f"DBeaver {latest_version}"
            create_sccm_application_via_ps(app_name, latest_version, download_path, config["ps_script_path"], config["install_command"])
        else:
            logging.error("Не удалось скачать файл.")
    else:
        logging.error("Не удалось получить версию DBeaver.")
