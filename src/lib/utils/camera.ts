const brightness = 1.18;

export const CAMERA_EFFECTS = {
	natural: { label: 'Natural', filter: 'none' },
	bright: { label: 'Terang', filter: `brightness(${brightness})` },
	mono: { label: 'Hitam putih', filter: 'grayscale(1)' }
} as const;

export type CameraEffect = keyof typeof CAMERA_EFFECTS;

export function drawCameraFrame(
	context: CanvasRenderingContext2D,
	video: HTMLVideoElement,
	effect: CameraEffect
) {
	// Draw in the camera's original orientation with no horizontal transform.
	context.drawImage(video, 0, 0);
	if (effect === 'natural') return;

	// Use pixel operations so the saved photo has the effect even without canvas filter support.
	const frame = context.getImageData(0, 0, context.canvas.width, context.canvas.height);
	const pixels = frame.data;
	for (let index = 0; index < pixels.length; index += 4) {
		if (effect === 'mono') {
			const luminance =
				pixels[index] * 0.2126 + pixels[index + 1] * 0.7152 + pixels[index + 2] * 0.0722;
			pixels[index] = luminance;
			pixels[index + 1] = luminance;
			pixels[index + 2] = luminance;
		} else {
			pixels[index] *= brightness;
			pixels[index + 1] *= brightness;
			pixels[index + 2] *= brightness;
		}
	}
	context.putImageData(frame, 0, 0);
}
