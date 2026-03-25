Feature: Target import transformations
  Importing a target file should preserve the expected column behavior.

  Scenario: Merging a target keeps existing values for ids not present in the import
    Given a source file "en.json" with messages
      | id    | defaultMessage |
      | hello | Hello          |
      | world | World          |
      | extra | Extra          |
    And an existing target file "de.json" with messages
      | id    | defaultMessage |
      | hello | Hallo          |
      | world | Welt           |
      | extra | Zusatz         |
    When I merge an imported target file "de.json" with messages
      | id    | defaultMessage |
      | hello | Guten Tag      |
      | world | Erde           |
    Then the target column "de" should contain
      | id    | value     |
      | hello | Guten Tag |
      | world | Erde      |
      | extra | Zusatz    |

  Scenario: Replacing a target clears existing values for ids not present in the import
    Given a source file "en.json" with messages
      | id    | defaultMessage |
      | hello | Hello          |
      | world | World          |
      | extra | Extra          |
    And an existing target file "de.json" with messages
      | id    | defaultMessage |
      | hello | Hallo          |
      | world | Welt           |
      | extra | Zusatz         |
    When I replace an imported target file "de.json" with messages
      | id    | defaultMessage |
      | hello | Guten Tag      |
      | world | Erde           |
    Then the target column "de" should contain
      | id    | value     |
      | hello | Guten Tag |
      | world | Erde      |
      | extra |           |

  Scenario: Merging a target keeps empty imported values
    Given a source file "en.json" with messages
      | id    | defaultMessage |
      | hello | Hello          |
      | world | World          |
      | extra | Extra          |
    And an existing target file "de.json" with messages
      | id    | defaultMessage |
      | hello | Hallo          |
      | world | Welt           |
      | extra | Zusatz         |
    When I merge an imported target file "de.json" with messages
      | id    | defaultMessage |
      | hello |                |
      | world | Erde           |
    Then the target column "de" should contain
      | id    | value  |
      | hello |        |
      | world | Erde   |
      | extra | Zusatz |

  Scenario: Replacing a target keeps empty imported values and clears missing ones
    Given a source file "en.json" with messages
      | id    | defaultMessage |
      | hello | Hello          |
      | world | World          |
      | extra | Extra          |
    And an existing target file "de.json" with messages
      | id    | defaultMessage |
      | hello | Hallo          |
      | world | Welt           |
      | extra | Zusatz         |
    When I replace an imported target file "de.json" with messages
      | id    | defaultMessage |
      | hello |                |
      | world | Erde           |
    Then the target column "de" should contain
      | id    | value |
      | hello |       |
      | world | Erde  |
      | extra |       |
