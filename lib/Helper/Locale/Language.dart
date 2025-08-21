import 'package:pos/Helper/Locale/keyabstract.dart';

class Language implements KeyAbstract {
  static const pos = "pos";
  static const dashboard = "dashboard";
  static const warehouse = "Warehouse";
  static const pointofsale = "PointofSale";
  static const search ="Search";
  static const sortby ="Sort By";
  static const sortbyname ="Name";
  static const product = "Product";
  static const category = "Category";
  static const brand = "Brand";
  static const supplier = "Supplier";
  static const customer = "Customer";
  static const employee = "Employee";
  static const from = "From";
  static const to = "To";
  static const date = "Date";
  static const total = "Total";
  static const action = "Action";
  static const addnewproduct = "Add New Product";
  static const editproduct = "Edit Product";
  static const name = "Name";
  static const price = "Price";
  static const quantity = "Quantity";
  static const description = "Description";

  


  @override
  static Map<String, Map<String, String>> keyMap = {
    'ar': {
      pos:'نظام نقطة البيع',
      dashboard:"لوحة تحكم",
      warehouse:"المخازن",
      pointofsale : "المبيعات",
      search :"بحث",
      sortby :"ترتيب حسب",
      sortbyname :"الاسم",
      product :'منتج',
      category :'الفئة',
      brand :'العلامة التجارية',
      supplier :'المورد',
      customer :'العميل',
      employee :'الموظف',
      from :"من",
      to :"إلى",
      date :"تاريخ",
      total :"مجموع",
      action :"عملية",
      addnewproduct :'أضف منتج جديد',
      editproduct :'تعديل المنتج',
    },
    "en": {
      pos: 'Point of Sale System',
      dashboard: "Control Panel ",
      warehouse: "Warehouse",
      pointofsale: "Sales",
      search :"Search",
      sortby :"Sort By",
      sortbyname :"Name",
      product :'Product',
      category :'Category',
      brand :'Brand',
      supplier :'Supplier',
      customer :'Customer',
      employee :'Employee',
      from :"From",
      to :"To",
      date :"Date",
      total :"Total",
      action :"Action",
  
    },
  };
}
