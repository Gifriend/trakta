import { compressPhoto, encodeJpeg } from './image';

export const PHOTO_FRAMES = {
	none: 'Tanpa bingkai',
	love: 'Love',
	stars: 'Bintang',
	retro: 'Retro Fotobox'
} as const;

export type PhotoEdits = {
	frame: keyof typeof PHOTO_FRAMES;
	turns: number;
	square: boolean;
};

export const DEFAULT_PHOTO_EDITS: PhotoEdits = { frame: 'none', turns: 0, square: false };

export function isPhotoFrame(value: string): value is PhotoEdits['frame'] {
	return Object.hasOwn(PHOTO_FRAMES, value);
}

export async function decodePhoto(dataUrl: string) {
	const image = new Image();
	image.src = dataUrl;
	try {
		await image.decode();
		return image;
	} catch {
		throw new Error('Foto gagal diproses. Coba foto lain.');
	}
}

function heart(context: CanvasRenderingContext2D, x: number, y: number, size: number) {
	context.save();
	context.translate(x, y);
	context.scale(size, size);
	context.beginPath();
	context.moveTo(0, 0.8);
	context.bezierCurveTo(-2.2, -0.7, -0.5, -1.45, 0, -0.55);
	context.bezierCurveTo(0.5, -1.45, 2.2, -0.7, 0, 0.8);
	context.fill();
	context.restore();
}

function sparkle(context: CanvasRenderingContext2D, x: number, y: number, size: number) {
	context.beginPath();
	context.moveTo(x, y - size);
	context.quadraticCurveTo(x + size * 0.18, y - size * 0.18, x + size, y);
	context.quadraticCurveTo(x + size * 0.18, y + size * 0.18, x, y + size);
	context.quadraticCurveTo(x - size * 0.18, y + size * 0.18, x - size, y);
	context.quadraticCurveTo(x - size * 0.18, y - size * 0.18, x, y - size);
	context.fill();
}

export function drawPhotoFrame(context: CanvasRenderingContext2D, frame: PhotoEdits['frame']) {
	const { width, height } = context.canvas;
	const unit = Math.min(width, height) / 100;
	const right = width / unit;
	const bottom = height / unit;
	context.save();
	context.scale(unit, unit);
	if (frame === 'love') {
		context.fillStyle = '#ff7699';
		heart(context, right - 9, 9, 5.5);
		heart(context, 9, bottom - 9, 5.5);
		context.fillStyle = '#ffe2ec';
		heart(context, right - 18, 6, 2.7);
		heart(context, 18, bottom - 6, 2.7);
	}
	if (frame === 'stars') {
		context.fillStyle = '#ffdc82';
		sparkle(context, 10, 10, 6);
		sparkle(context, right - 10, bottom - 10, 6);
		context.fillStyle = '#fff7df';
		sparkle(context, 19, 6, 2.8);
		sparkle(context, right - 19, bottom - 6, 2.8);
	}
	if (frame === 'retro') {
		context.strokeStyle = '#fff1d8';
		context.lineWidth = 5;
		context.strokeRect(2.5, 2.5, right - 5, bottom - 5);
		context.fillStyle = '#fff1d8';
		context.fillRect(0, bottom - 10, right, 10);
		context.fillStyle = '#70462f';
		context.font = 'bold 4px monospace';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillText('TRAKTA', right / 2, bottom - 4.8);
		sparkle(context, 9, bottom - 4.8, 1.6);
		sparkle(context, right - 9, bottom - 4.8, 1.6);
	}
	context.restore();
}

export function renderEditedPhoto(
	canvas: HTMLCanvasElement,
	image: HTMLImageElement,
	edits: PhotoEdits,
	maxEdge: number
) {
	const sourceWidth = image.naturalWidth;
	const sourceHeight = image.naturalHeight;
	const crop = Math.min(sourceWidth, sourceHeight);
	const width = edits.square ? crop : sourceWidth;
	const height = edits.square ? crop : sourceHeight;
	const scale = Math.min(1, maxEdge / Math.max(width, height));
	const rotatedWidth = Math.max(1, Math.round(width * scale));
	const rotatedHeight = Math.max(1, Math.round(height * scale));
	const sideways = edits.turns % 2 === 1;
	canvas.width = sideways ? rotatedHeight : rotatedWidth;
	canvas.height = sideways ? rotatedWidth : rotatedHeight;
	const context = canvas.getContext('2d');
	if (!context) throw new Error('Browser tidak mendukung pengolahan foto.');

	context.save();
	context.translate(canvas.width / 2, canvas.height / 2);
	context.rotate((edits.turns * Math.PI) / 2);
	context.drawImage(
		image,
		(sourceWidth - width) / 2,
		(sourceHeight - height) / 2,
		width,
		height,
		-rotatedWidth / 2,
		-rotatedHeight / 2,
		rotatedWidth,
		rotatedHeight
	);
	context.restore();
	drawPhotoFrame(context, edits.frame);
}
export async function saveEditedPhoto(image: HTMLImageElement, edits: PhotoEdits) {
	const canvas = document.createElement('canvas');
	renderEditedPhoto(canvas, image, edits, 1280);
	const blob = await encodeJpeg(canvas, 0.96);
	return compressPhoto(new File([blob], 'trakta-fotobox.jpg', { type: 'image/jpeg' }));
}
