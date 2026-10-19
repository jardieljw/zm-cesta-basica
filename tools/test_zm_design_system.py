import unittest
from check_zm_design_system import detect_added, validate_contract

class DesignGateTests(unittest.TestCase):
    def test_contract_is_grounded(self):
        report = validate_contract()
        self.assertEqual(report["views"], 38)
        self.assertEqual(report["components"], 20)
        self.assertEqual(report["tokens"], 33)

    def test_reject_new_page_local_styles(self):
        cases = {
            "TextStyle(fontSize: 13)": "typography",
            "backgroundColor: Colors.red,": "color_palette",
            "BorderRadius.circular(12)": "geometry",
            "decoration: InputDecoration(labelText: 'X')": "input_style",
            "await showDatePicker(context: context)": "datepicker",
            "showDateRangePicker(context: context)": "date_range_picker",
            "return Scaffold(": "independent_page_shell",
            "appBar: AppBar(": "independent_page_shell",
            "icon: const Icon(Icons.add)": "raw_icon_family",
            "child: FilterChip(": "raw_filter_control",
            "child: ChoiceChip(": "raw_filter_control",
            "child: ExpansionTile(": "raw_filter_control",
            "child: SegmentedButton<bool>(": "raw_filter_control",
            "child: TextField(": "raw_input_control",
            "child: TextFormField(": "raw_input_control",
            "child: DropdownButtonFormField<String>(": "raw_input_control",
            "padding: EdgeInsets.only(left: 12)": "local_spacing",
            "fontSize: 14,": "literal_font_size",
        }
        for code, rule in cases.items():
            with self.subTest(code=code):
                self.assertIn(rule, detect_added(code, set()))

    def test_allow_component_reuse(self):
        self.assertEqual(detect_added("return ApprovedDateButton(date: day, onDateSelected: callback);", set()), [])
        self.assertEqual(detect_added("child: ApprovedCollapsibleFilter(expanded: open, onToggle: toggle, label: label, summary: summary, content: child),", set()), [])

    def test_exceptions_must_be_explicitly_registered(self):
        line = "TextStyle(fontSize: 14) // zm-design-exception: EX-001"
        self.assertEqual(set(detect_added(line, set())), {"typography", "literal_font_size"})
        self.assertEqual(detect_added(line, {"EX-001"}), [])

if __name__ == "__main__":
    unittest.main()
