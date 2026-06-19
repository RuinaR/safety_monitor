# Ubuntu 서버 실행 가이드

이 문서는 중앙 서버(`safety_monitor_server`)만 Ubuntu에서 실행할 때의 절차입니다. 클라이언트와 뷰어는 현재 Windows Flutter 앱 기준으로 유지하고, 서버 주소만 Ubuntu 서버 IP로 바꿔 접속합니다.

## 빠른 결론

Ubuntu 서버에 프로젝트 폴더가 `/opt/safety_monitor`로 들어가 있다면 아래 명령을 그대로 실행하면 됩니다.

```bash
cd /opt/safety_monitor

sudo apt update
sudo apt install -y python3.12 python3.12-venv python3-pip libgl1 libglib2.0-0t64

python3.12 -m venv .venv
. .venv/bin/activate

python -m pip install --upgrade pip
python -m pip install -r requirements-server.txt

chmod +x run_server.sh
./run_server.sh
```

단, 위 명령이 성공하려면 먼저 이 워크스페이스 전체가 Ubuntu의 `/opt/safety_monitor` 폴더에 있어야 합니다. 아직 옮기지 않았다면 아래의 `프로젝트를 Ubuntu로 옮기는 방법`을 먼저 진행합니다.

## 프로젝트를 Ubuntu로 옮기는 방법

가장 권장하는 방법은 Git으로 받는 것입니다. 저장소 URL을 알고 있고 Ubuntu 서버가 인터넷 또는 사내 Git 서버에 접근할 수 있으면 이 방법이 가장 깔끔합니다.

```bash
cd /opt
sudo git clone <저장소 URL> safety_monitor
sudo chown -R "$USER":"$USER" /opt/safety_monitor
cd /opt/safety_monitor
```

Git URL을 모르면 Windows에서 현재 폴더의 원격 주소를 확인합니다.

```bat
git remote -v
```

이미 Ubuntu에 한 번 받아둔 뒤 최신 내용만 반영하려면 다음만 실행합니다.

```bash
cd /opt/safety_monitor
git pull
```

Git을 쓰기 어렵다면 Windows에서 ZIP으로 묶어서 옮겨도 됩니다. 이때 `.venv`, `build`, `logs`, `.tmp` 같은 실행 산출물은 빼고 옮기는 편이 좋습니다.

Windows PowerShell 예시:

```powershell
Compress-Archive -Path C:\safety_monitor\* -DestinationPath C:\safety_monitor.zip
```

Ubuntu로 `scp` 전송 예시:

```powershell
scp C:\safety_monitor.zip ubuntu@<Ubuntu서버IP>:/tmp/safety_monitor.zip
```

Ubuntu에서 압축 해제:

```bash
sudo apt install -y unzip
sudo mkdir -p /opt/safety_monitor
sudo unzip /tmp/safety_monitor.zip -d /opt/safety_monitor
sudo chown -R "$USER":"$USER" /opt/safety_monitor
cd /opt/safety_monitor
```

USB나 공유폴더로 옮기는 경우에도 최종적으로 Ubuntu 안의 폴더 구조가 아래처럼 보이면 됩니다.

```text
/opt/safety_monitor/
├─ safety_monitor_server/
├─ safety_monitor_client/
├─ safety_monitor_viewer/
├─ requirements-server.txt
├─ run_server.sh
└─ README.md
```

서버만 실행하더라도 처음에는 워크스페이스 전체를 옮겨도 괜찮습니다. 실제 Ubuntu 서버 실행에 주로 필요한 것은 `safety_monitor_server/`, `requirements-server.txt`, `run_server.sh`입니다.

## 1. 전체 구조에서 바뀌는 점

기존 Windows 전체 실행:

```text
Windows 서버 PC: run_server.bat
Windows 뷰어 PC: run_viewer.bat
Windows 클라이언트 PC: run_client.bat
```

Ubuntu 서버 전환 후:

```text
Ubuntu 서버: ./run_server.sh 또는 uvicorn 직접 실행
Windows 뷰어 PC: run_viewer.bat
Windows 클라이언트 PC: run_client.bat
```

뷰어와 클라이언트에 입력하는 서버 URL은 다음처럼 Ubuntu 서버의 IP를 사용합니다.

```text
http://<Ubuntu 서버 IP>:8000
```

다른 PC에서 접속할 때 `127.0.0.1`을 입력하면 안 됩니다. `127.0.0.1`은 항상 현재 PC 자기 자신을 뜻합니다.

## 2. Ubuntu 권장 환경

- Ubuntu 24.04 LTS 권장
- Python 3.12 권장
- TCP 8000 포트를 열 수 있는 네트워크 환경

서버는 로컬 카메라를 직접 열거나 GPU 추론을 하지 않습니다. 따라서 클라이언트용 YOLO, TensorRT, Flutter, Visual Studio Build Tools는 Ubuntu 서버에 설치하지 않습니다.

## 3. 패키지 설치

Ubuntu 서버에서 실행합니다.

```bash
sudo apt update
sudo apt install -y git python3.12 python3.12-venv python3-pip libgl1 libglib2.0-0t64
```

`libgl1`, `libglib2.0-0t64`은 서버가 OpenCV로 프리뷰 이미지와 이벤트 클립/썸네일을 처리할 때 필요한 런타임 라이브러리입니다.

## 4. 프로젝트 받기

예시는 `/opt/safety_monitor`에 두는 방식입니다. 홈 디렉터리 아래에 두어도 됩니다.

```bash
cd /opt
sudo git clone <저장소 URL> safety_monitor
sudo chown -R "$USER":"$USER" /opt/safety_monitor
cd /opt/safety_monitor
```

이미 받은 저장소라면 최신 코드만 가져옵니다.

```bash
cd /opt/safety_monitor
git pull
```

## 5. Python 가상환경 준비

```bash
cd /opt/safety_monitor
python3.12 -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements-server.txt
```

서버 의존성은 루트의 `requirements-server.txt`가 기준입니다. `requirements.txt`는 클라이언트 내장 백엔드/AI 쪽 의존성이므로 Ubuntu 중앙 서버에는 설치하지 않습니다.

## 6. 서버 실행

간단 실행:

```bash
cd /opt/safety_monitor
chmod +x run_server.sh
./run_server.sh
```

직접 실행:

```bash
cd /opt/safety_monitor/safety_monitor_server
../.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000 --no-access-log
```

서버가 켜졌는지 Ubuntu 서버 자기 자신에서 확인합니다.

```bash
curl http://127.0.0.1:8000/health
```

다른 PC에서는 아래 주소를 브라우저로 열어 확인합니다.

```text
http://<Ubuntu 서버 IP>:8000/health
```

## 7. 방화벽 열기

Ubuntu에서 `ufw`를 쓰는 경우:

```bash
sudo ufw allow 8000/tcp
sudo ufw status
```

클라우드 VM이나 사내 서버라면 Ubuntu 내부 방화벽과 별개로 보안 그룹, 네트워크 ACL, 공유기 포트 정책에서도 TCP 8000이 허용되어야 합니다.

## 8. 백그라운드 서비스로 등록

운영처럼 서버를 계속 켜둘 때는 `systemd` 서비스를 권장합니다.

```bash
sudo nano /etc/systemd/system/safety-monitor-server.service
```

아래에서 `User`, `WorkingDirectory`, `ExecStart`, `Environment` 경로를 실제 위치에 맞춥니다.

```ini
[Unit]
Description=Safety Monitor FastAPI Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/safety_monitor/safety_monitor_server
Environment=SAFETY_MONITOR_LOG_FILE=/opt/safety_monitor/logs/server.log
ExecStart=/opt/safety_monitor/.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000 --no-access-log
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

서비스 적용:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now safety-monitor-server
sudo systemctl status safety-monitor-server
```

로그 확인:

```bash
journalctl -u safety-monitor-server -f
tail -f /opt/safety_monitor/logs/server.log
```

서비스 재시작:

```bash
sudo systemctl restart safety-monitor-server
```

## 9. 데이터 위치

서버 데이터는 저장소 내부에 생성됩니다.

```text
safety_monitor_server/data/monitor.db
safety_monitor_server/data/clips/
safety_monitor_server/data/event_thumbnails/
safety_monitor_server/data/source_previews/
```

Ubuntu에서 운영할 때는 이 폴더를 정기 백업 대상에 포함합니다. 테스트 중 데이터를 초기화하려면 뷰어의 `DB Clear`를 사용합니다.

## 10. 자주 막히는 지점

### 다른 PC에서 `/health`가 안 열림

1. 서버가 켜져 있는지 확인합니다: `systemctl status safety-monitor-server`
2. 서버에서 직접 확인합니다: `curl http://127.0.0.1:8000/health`
3. Ubuntu IP를 확인합니다: `hostname -I`
4. 방화벽을 확인합니다: `sudo ufw status`
5. 클라우드/공유기/사내망 포트 정책에서 TCP 8000이 열려 있는지 확인합니다.

### `ModuleNotFoundError`가 뜸

가상환경을 활성화하지 않았거나 서버 의존성을 설치하지 않은 상태입니다.

```bash
cd /opt/safety_monitor
. .venv/bin/activate
python -m pip install -r requirements-server.txt
```

### OpenCV import 오류가 뜸

Ubuntu 런타임 라이브러리를 설치합니다.

```bash
sudo apt install -y libgl1 libglib2.0-0t64
```

### Windows 뷰어/클라이언트가 서버에 붙지 않음

뷰어/클라이언트 서버 URL이 `http://<Ubuntu 서버 IP>:8000`인지 확인합니다. Windows PC에서 `127.0.0.1`을 넣으면 Ubuntu 서버가 아니라 Windows PC 자신을 보게 됩니다.
