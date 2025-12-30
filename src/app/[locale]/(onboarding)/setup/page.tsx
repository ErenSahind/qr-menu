"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { nanoid } from "nanoid";

export default function SetupPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    branchName: "",
    slug: "",
    tableCount: 10,
    useTableNumbers: true,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    // e.preventDefault();
    // setLoading(true);
    // try {
    //   // 1. Kullanıcıyı al
    //   const {
    //     data: { user },
    //   } = await supabase.auth.getUser();
    //   if (!user) throw new Error("Kullanıcı oturumu bulunamadı.");
    //   // 2. Şubeyi oluştur
    //   const { data: branch, error: branchError } = await supabase
    //     .from("branches")
    //     .insert({
    //       owner_id: user.id,
    //       name: formData.branchName,
    //       slug: formData.slug,
    //     })
    //     .select()
    //     .single();
    //   if (branchError) throw branchError;
    //   // 3. Masaları oluştur
    //   if (formData.tableCount > 0) {
    //     const tables = Array.from({ length: formData.tableCount }).map(
    //       (_, i) => ({
    //         branch_id: branch.id,
    //         table_number: (i + 1).toString(),
    //         qr_code: nanoid(5), // 5 karakterlik ID
    //       })
    //     );
    //     const { error: tablesError } = await supabase
    //       .from("tables")
    //       .insert(tables);
    //     if (tablesError) throw tablesError;
    //   }
    //   // 4. Başarılı, dashboard'a git
    //   router.push("/dashboard");
    //   router.refresh();
    // } catch (error: any) {
    //   console.error("Setup Error:", error);
    //   alert("Bir hata oluştu: " + error.message);
    // } finally {
    //   setLoading(false);
    // }
  };

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-center">
        İlk Şubenizi Oluşturun
      </h1>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700">
            Şube Adı
          </label>
          <input
            type="text"
            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm p-2 focus:ring-blue-500 focus:border-blue-500"
            value={formData.branchName}
            onChange={(e) =>
              setFormData({ ...formData, branchName: e.target.value })
            }
            required
            placeholder="Örn: Kadıköy Şubesi"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">
            Link (Slug)
          </label>
          <div className="mt-1 flex rounded-md shadow-sm">
            <span className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
              qr-menu.com/qr/
            </span>
            <input
              type="text"
              className="flex-1 block w-full border border-gray-300 rounded-r-md p-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="sube-adi"
              value={formData.slug}
              onChange={(e) =>
                setFormData({ ...formData, slug: e.target.value })
              }
              required
            />
          </div>
        </div>

        <div className="flex items-center">
          <input
            id="use-tables"
            type="checkbox"
            className="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            checked={formData.useTableNumbers}
            onChange={(e) =>
              setFormData({ ...formData, useTableNumbers: e.target.checked })
            }
          />
          <label
            htmlFor="use-tables"
            className="ml-2 block text-sm text-gray-900"
          >
            Masa numarası kullanacağım
          </label>
        </div>

        {formData.useTableNumbers && (
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Masa Sayısı
            </label>
            <input
              type="number"
              min="1"
              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm p-2 focus:ring-blue-500 focus:border-blue-500"
              value={formData.tableCount}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  tableCount: parseInt(e.target.value),
                })
              }
            />
          </div>
        )}

        <button
          type="submit"
          className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          Kurulumu Tamamla
        </button>
      </form>
    </div>
  );
}
