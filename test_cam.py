import cv2

for i in range(5):
    cap = cv2.VideoCapture(i)
    if cap.isOpened():
        ok, frame = cap.read()
        print(f"Cam {i}: opened={ok}, frame={'OK' if frame is not None else 'None'}")
        cap.release()
