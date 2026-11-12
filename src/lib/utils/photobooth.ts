import type { CompressedPhoto } from '#lib/types/attendance.ts';
import { decodePhoto } from './photo-editor';
import { compressPhoto, encodeJpeg } from './image';

export async function composePhotoBooth(
	photos: CompressedPhoto[],
	layout: 'strip' | 'grid',
	color: string
) {
	const images = await Promise.all(photos.map((photo) => decodePhoto(photo.dataUrl)));
	const columns = layout === 'grid' ? 2 : 1;
	const rows = Math.ceil(images.length / columns);
	const gap = 24;
	const cellWidth = 480;
	const cellHeight = 360;
	const canvas = document.createElement('canvas');
	canvas.width = columns * cellWidth + (columns + 1) * gap;
	canvas.height = rows * cellHeight + (rows + 1) * gap + 52;
	const context = canvas.getContext('2d');
	if (!context) throw new Error('Browser tidak mendukung pengolahan foto.');
	context.fillStyle = color;
	context.fillRect(0, 0, canvas.width, canvas.height);
	images.forEach((image, index) => {
		const x = gap + (index % columns) * (cellWidth + gap);
		const y = gap + Math.floor(index / columns) * (cellHeight + gap);
		const scale = Math.max(cellWidth / image.naturalWidth, cellHeight / image.naturalHeight);
		const width = cellWidth / scale;
		const height = cellHeight / scale;
		context.drawImage(
			image,
			(image.naturalWidth - width) / 2,
			(image.naturalHeight - height) / 2,
			width,
			height,
			x,
			y,
			cellWidth,
			cellHeight
		);
	});
	context.fillStyle = '#124e43';
	context.font = 'bold 22px sans-serif';
	context.textAlign = 'center';
	context.fillText('TRAKTA', canvas.width / 2, canvas.height - 24);
	return compressPhoto(
		new File([await encodeJpeg(canvas, 0.96)], 'trakta-fotobox.jpg', { type: 'image/jpeg' })
	);
}
