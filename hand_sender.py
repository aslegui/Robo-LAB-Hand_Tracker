import cv2
import json
import socket
import time
import mediapipe as mp

UDP_IP = "127.0.0.1"
UDP_PORT = 9005

CAM_INDEX_PRIMARY = 1
CAM_INDEX_FALLBACK = 0

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    model_complexity=1,
    min_detection_confidence=0.6,
    min_tracking_confidence=0.6
)

def open_camera(index: int):
    cap = cv2.VideoCapture(index)
    if cap.isOpened():
        return cap
    cap.release()
    return None

cap = open_camera(CAM_INDEX_PRIMARY)
if cap is None:
    print(f"[hand_sender] No pude abrir cam {CAM_INDEX_PRIMARY}, probando cam {CAM_INDEX_FALLBACK}...")
    cap = open_camera(CAM_INDEX_FALLBACK)

if cap is None:
    raise RuntimeError("[hand_sender] No se pudo abrir ninguna cámara (0 ni 1).")

def pack_hand(hand_landmarks, label, score):
    pts = [[float(lm.x), float(lm.y), float(lm.z)] for lm in hand_landmarks.landmark]
    return {"label": label, "score": float(score), "landmarks": pts}

print(f"[hand_sender] Camera OK. Sending UDP to {UDP_IP}:{UDP_PORT}. ESC para salir.")

while True:
    ok, frame = cap.read()
    if not ok or frame is None:
        print("[hand_sender] No frame recibido. Reintentando...")
        time.sleep(0.05)
        continue

    # Procesar SIN espejo (para que Left/Right sea correcto)
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    res = hands.process(frame_rgb)

    payload = {"t": int(time.time() * 1000), "hands": []}

    if res.multi_hand_landmarks and res.multi_handedness:
        for hlm, hinfo in zip(res.multi_hand_landmarks, res.multi_handedness):
            label = hinfo.classification[0].label  # correcto
            score = hinfo.classification[0].score
            payload["hands"].append(pack_hand(hlm, label, score))

    msg = json.dumps(payload).encode("utf-8")
    sock.sendto(msg, (UDP_IP, UDP_PORT))

    print(f"sent={len(msg)} bytes | hands={len(payload['hands'])}     ", end="\r")

    # Vista espejada solo para el usuario (opcional)
    preview = cv2.flip(frame, 1)
    cv2.imshow("cam", preview)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()
hands.close()
print("\n[hand_sender] stopped.")