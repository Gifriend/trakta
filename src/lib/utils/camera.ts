type ColorRow = readonly [red: number, green: number, blue: number, offset?: number];
type ColorMatrix = readonly [red: ColorRow, green: ColorRow, blue: ColorRow];

function channelMatrix(scale: number, offset = 0): ColorMatrix {
	return [
		[scale, 0, 0, offset],
		[0, scale, 0, offset],
		[0, 0, scale, offset]
	];
}

function contrastEffect(label: string, amount: number) {
	return {
		label,
		filter: `contrast(${amount})`,
		matrix: channelMatrix(amount, (255 / 2) * (1 - amount))
	};
}

const brightness = 1.18;
const saturation = 1.45;
const gray: ColorRow = [0.2126, 0.7152, 0.0722];
const saturationRed = 0.213 * (1 - saturation);
const saturationGreen = 0.715 * (1 - saturation);
const saturationBlue = 0.072 * (1 - saturation);

export const CAMERA_EFFECTS = {
	natural: { label: 'Natural', filter: 'none', matrix: null },
	bright: {
		label: 'Terang',
		filter: `brightness(${brightness})`,
		matrix: channelMatrix(brightness)
	},
	mono: { label: 'Hitam putih', filter: 'grayscale(1)', matrix: [gray, gray, gray] },
	sepia: {
		label: 'Sepia',
		filter: 'sepia(1)',
		matrix: [
			[0.393, 0.769, 0.189],
			[0.349, 0.686, 0.168],
			[0.272, 0.534, 0.131]
		]
	},
	vivid: {
		label: 'Warna hidup',
		filter: `saturate(${saturation})`,
		matrix: [
			[saturationRed + saturation, saturationGreen, saturationBlue],
			[saturationRed, saturationGreen + saturation, saturationBlue],
			[saturationRed, saturationGreen, saturationBlue + saturation]
		]
	},
	contrast: contrastEffect('Kontras tinggi', 1.3),
	soft: contrastEffect('Lembut', 0.8)
} satisfies Record<string, { label: string; filter: string; matrix: ColorMatrix | null }>;

export type CameraEffect = keyof typeof CAMERA_EFFECTS;

export function isCameraEffect(value: string | null): value is CameraEffect {
	return value !== null && Object.hasOwn(CAMERA_EFFECTS, value);
}

export function drawCameraFrame(
	context: CanvasRenderingContext2D,
	video: HTMLVideoElement,
	effect: CameraEffect,
	correctMirroring: boolean
) {
	context.save();
	if (correctMirroring) context.setTransform(-1, 0, 0, 1, context.canvas.width, 0);
	context.drawImage(video, 0, 0);
	context.restore();
	const matrix = CAMERA_EFFECTS[effect].matrix;
	if (!matrix) return;

	// Apply the CSS filter's color matrix on browsers without relying on canvas filter support.
	const [
		[redRed, redGreen, redBlue, redOffset = 0],
		[greenRed, greenGreen, greenBlue, greenOffset = 0],
		[blueRed, blueGreen, blueBlue, blueOffset = 0]
	] = matrix;
	const frame = context.getImageData(0, 0, context.canvas.width, context.canvas.height);
	const pixels = frame.data;
	for (let index = 0; index < pixels.length; index += 4) {
		const red = pixels[index];
		const green = pixels[index + 1];
		const blue = pixels[index + 2];
		pixels[index] = red * redRed + green * redGreen + blue * redBlue + redOffset;
		pixels[index + 1] = red * greenRed + green * greenGreen + blue * greenBlue + greenOffset;
		pixels[index + 2] = red * blueRed + green * blueGreen + blue * blueBlue + blueOffset;
	}
	context.putImageData(frame, 0, 0);
}
