import Link from "next/link";

export default async function LandingPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  return (
    <div className="min-h-screen flex flex-col">
      {/* Navbar */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="text-2xl font-bold text-blue-600">QR Menu SaaS</div>
          <nav className="space-x-4">
            <Link
              href={`/${locale}/login`}
              className="text-gray-600 hover:text-gray-900"
            >
              Giriş Yap
            </Link>
            <Link
              href={`/${locale}/register`}
              className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
            >
              Ücretsiz Dene
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <main className="flex-1">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 text-center">
          <h1 className="text-5xl font-extrabold text-gray-900 mb-6">
            Restoranınız için Modern QR Menü
          </h1>
          <p className="text-xl text-gray-500 mb-10 max-w-2xl mx-auto">
            Müşterilerinize temassız, hızlı ve modern bir menü deneyimi sunun.
            Dakikalar içinde menünüzü oluşturun ve QR kodlarınızı masalarınıza
            yapıştırın.
          </p>
          <div className="flex justify-center gap-4">
            <Link
              href={`/${locale}/register`}
              className="bg-blue-600 text-white px-8 py-3 rounded-lg text-lg font-semibold hover:bg-blue-700"
            >
              Hemen Başla
            </Link>
            <Link
              href="#features"
              className="bg-gray-100 text-gray-700 px-8 py-3 rounded-lg text-lg font-semibold hover:bg-gray-200"
            >
              Özellikleri İncele
            </Link>
          </div>
        </div>

        {/* Features Section (Placeholder) */}
        <div id="features" className="bg-gray-50 py-20">
          <div className="max-w-7xl mx-auto px-4">
            <h2 className="text-3xl font-bold text-center mb-12">Neden Biz?</h2>
            <div className="grid md:grid-cols-3 gap-8">
              <div className="bg-white p-6 rounded-lg shadow">
                <h3 className="text-xl font-bold mb-2">Kolay Yönetim</h3>
                <p>Menünüzü dilediğiniz zaman güncelleyin, anında yansısın.</p>
              </div>
              <div className="bg-white p-6 rounded-lg shadow">
                <h3 className="text-xl font-bold mb-2">Masa Bazlı QR</h3>
                <p>
                  Her masa için özel QR kodlar oluşturun, siparişleri
                  karıştırmayın.
                </p>
              </div>
              <div className="bg-white p-6 rounded-lg shadow">
                <h3 className="text-xl font-bold mb-2">İstatistikler</h3>
                <p>Hangi ürünün ne kadar görüntülendiğini takip edin.</p>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-8">
        <div className="max-w-7xl mx-auto px-4 text-center">
          <p>&copy; 2025 QR Menu SaaS. Tüm hakları saklıdır.</p>
        </div>
      </footer>
    </div>
  );
}
