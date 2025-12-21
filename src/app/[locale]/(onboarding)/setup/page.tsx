"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function SetupPage() {
  const router = useRouter();
  const [formData, setFormData] = useState({
    branchName: "",
    slug: "",
    tableCount: 1,
    useTableNumbers: true,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // API call to save branch details
    // await createBranch(formData);

    // Başarılı olursa dashboard'a yönlendir
    router.push("/dashboard");
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
