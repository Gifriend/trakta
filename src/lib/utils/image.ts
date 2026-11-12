import type { CompressedPhoto } from '#lib/types/attendance.ts';

// Decimal KB: stricter than 100 KiB, and validated again by Firestore rules.
export const MAX_PHOTO_BYTES = 100_000;
export const MAX_INPUT_BYTES = 20_000_000;

export function encodeJpeg(canvas: HTMLCanvasElement, quality: number): Promise<Blob> {
	return new Promise((resolve, reject) => {
		canvas.toBlob(
			(blob) => (blob ? resolve(blob) : reject(new Error('Foto gagal diproses. Coba foto lain.'))),
			'image/jpeg',
			quality
		);
	});
}

export async function compressPhoto(file: File): Promise<CompressedPhoto> {
	if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
		throw new Error('Gunakan foto JPG, PNG, atau WebP. Ubah foto HEIC ke JPG terlebih dahulu.');
	}
	if (file.size > MAX_INPUT_BYTES) throw new Error('Ukuran foto awal maksimal 20 MB.');
	if (!file.size) throw new Error('File foto kosong. Pilih foto lain.');

	let bitmap: ImageBitmap;
	try {
		bitmap = await createImageBitmap(file, { imageOrientation: 'from-image' });
	} catch {
		throw new Error('Foto tidak dapat dibaca. Pilih foto JPG, PNG, atau WebP yang valid.');
	}
	try {
		const canvas = document.createElement('canvas');
		const context = canvas.getContext('2d');
		if (!context) throw new Error('Browser tidak mendukung pengolahan foto.');
		let edge = Math.min(1280, Math.max(bitmap.width, bitmap.height));
		for (let round = 0; round < 9; round++) {
			const scale = edge / Math.max(bitmap.width, bitmap.height);
			canvas.width = Math.max(1, Math.round(bitmap.width * scale));
			canvas.height = Math.max(1, Math.round(bitmap.height * scale));
			context.fillStyle = '#ffffff';
			context.fillRect(0, 0, canvas.width, canvas.height);
			context.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
			let best = await encodeJpeg(canvas, 0.35);
			if (best.size <= MAX_PHOTO_BYTES) {
				let low = 0.35;
				let high = 0.92;
				for (let step = 0; step < 7; step++) {
					const quality = (low + high) / 2;
					const candidate = await encodeJpeg(canvas, quality);
					if (candidate.size <= MAX_PHOTO_BYTES) {
						best = candidate;
						low = quality;
					} else high = quality;
				}
				const dataUrl = await new Promise<string>((resolve, reject) => {
					const reader = new FileReader();
					reader.onload = () => resolve(String(reader.result));
					reader.onerror = () => reject(new Error('Foto gagal dibaca. Silakan coba lagi.'));
					reader.readAsDataURL(best);
				});
				return {
					base64: dataUrl.split(',')[1],
					dataUrl,
					bytes: best.size,
					width: canvas.width,
					height: canvas.height
				};
			}
			edge = Math.round(edge * 0.75);
		}
		throw new Error('Foto belum bisa diperkecil menjadi 100 KB. Pilih foto lain.');
	} finally {
		bitmap.close();
	}
}
