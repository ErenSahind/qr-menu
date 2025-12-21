import { redirect } from 'next/navigation';

// Bu layout, dashboard altındaki tüm sayfaları kapsar.
// Kullanıcının setup işlemini tamamlayıp tamamlamadığını kontrol eder.

async function checkUserSetup() {
  // Simüle edilmiş veritabanı kontrolü
  // Gerçekte: const user = await db.user.find(session.user.id);
  const isSetupComplete = false; // Bu değeri DB'den alacağız.

  return isSetupComplete;
}

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const isSetupComplete = await checkUserSetup();

  if (!isSetupComplete) {
    // Eğer şirket bilgilerini girmemişse setup sayfasına zorla
    redirect('/setup');
  }

  return (
    <div className="flex h-screen bg-gray-100">
      <aside className="w-64 bg-white shadow-md">
        <div className="p-4 font-bold text-xl">QR Menu Dashboard</div>
        <nav className="mt-4">
          <a href="/dashboard" className="block p-4 hover:bg-gray-50">Genel Bakış</a>
          <a href="/qr-management" className="block p-4 hover:bg-gray-50">QR Kodlarım</a>
          <a href="/menu-editor" className="block p-4 hover:bg-gray-50">Menü Düzenle</a>
        </nav>
      </aside>
      <main className="flex-1 p-8 overflow-y-auto">
        {children}
      </main>
    </div>
  );
}
