import { Skeleton } from "@/components/ui/skeleton";

export default function DashboardLoading() {
  return (
    <div className="flex flex-col space-y-6 p-8">
      {/* Başlık Alanı */}
      <div className="flex items-center justify-between space-y-2">
        <div>
          <Skeleton className="h-8 w-[200px]" />
          <Skeleton className="mt-2 h-4 w-[300px]" />
        </div>
        <div className="flex items-center space-x-2">
          <Skeleton className="h-10 w-[120px]" />
        </div>
      </div>

      {/* İstatistik Kartları (4'lü Grid) */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div
            key={i}
            className="rounded-xl border bg-card text-card-foreground shadow p-6"
          >
            <div className="flex flex-row items-center justify-between space-y-0 pb-2">
              <Skeleton className="h-4 w-[100px]" />
              <Skeleton className="h-4 w-4" />
            </div>
            <div className="mt-2">
              <Skeleton className="h-8 w-[60px]" />
              <Skeleton className="mt-1 h-3 w-[140px]" />
            </div>
          </div>
        ))}
      </div>

      {/* Büyük Grafik veya Tablo Alanı */}
      <Skeleton className="h-[400px] w-full rounded-xl" />
    </div>
  );
}
