import { notFound } from "next/navigation";

// Bu sayfa müşterinin gördüğü menü sayfasıdır.
// URL: /qr/[slug]/[tableId]
// Örnek: /qr/starbucks/x7Ka2bP9

interface PageProps {
  params: {
    locale: string;
    branchSlug: string;
    tableId: string;
  };
}

export default function MenuPage({ params }: PageProps) {
  // 1. branchSlug ile şubeyi bul
  // 2. tableId ile masayı doğrula (NanoID kontrolü - 7-10 karakter)

  // Simüle edilmiş kontrol
  const isValidTable = true; // await checkTableExists(params.tableId);

  if (!isValidTable) {
    return <div className="p-4 text-center text-red-500">Geçersiz QR Kod</div>;
  }

  return (
    <div className="max-w-md mx-auto bg-white min-h-screen shadow-lg">
      <header className="bg-orange-500 p-4 text-white">
        <h1 className="text-xl font-bold">Şube: {params.branchSlug}</h1>
        <p className="text-sm opacity-90">Masa ID: {params.tableId}</p>
        <p className="text-xs opacity-75">Dil: {params.locale}</p>
      </header>

      <main className="p-4">
        <div className="space-y-4">
          {/* Kategori ve Ürünler burada listelenecek */}
          <div className="border rounded-lg p-4 shadow-sm">
            <h3 className="font-bold">Latte</h3>
            <p className="text-gray-500">Sütlü kahve</p>
            <div className="mt-2 font-bold text-orange-600">90 ₺</div>
            <button className="mt-2 w-full bg-orange-100 text-orange-600 py-1 rounded">
              Ekle
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}
