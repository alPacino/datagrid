require 'spec_helper'

describe Datagrid::Columns do

  let(:group) { Group.create!(:name => "Pop") }

  subject do
    SimpleReport.new
  end

  describe "basic methods" do

    let!(:entry) {  Entry.create!(
      :group => group, :name => "Star", :disabled => false, :confirmed => false, :category => "first"
    ) }

    it "should have data columns without html columns" do
      subject.data_columns.size.should == subject.columns.size - 1
    end
    it "should build rows of data" do
      subject.rows.should == [["Pop", "Star"]]
    end
    it  "should generate header" do
      subject.header.should == ["Group", "Name"]
    end

    it "should generate table data" do
      subject.data.should == [
        subject.header,
        subject.row_for(entry)
      ]
    end

    it "should generate hash for given asset" do
      subject.hash_for(entry).should == {
        :group => "Pop",
        :name => "Star"
      }
    end

    it "should support csv export" do
      subject.to_csv.should == "Group,Name\nPop,Star\n"
    end
  end

  it "should support columns with model and report arguments" do
    report = test_report(:category => "foo") do
      scope {Entry.order(:category)}
      filter(:category) do |value|
        where("category LIKE '%#{value}%'")
      end

      column(:exact_category) do |entry, report|
        entry.category == report.category
      end
    end
    Entry.create!(:category => "foo")
    Entry.create!(:category => "foobar")
    report.rows.first.first.should be_true
    report.rows.last.first.should be_false
  end

  it "should inherit columns correctly" do
    parent_class = Class.new do
      include Datagrid
      scope { Entry }
      column(:name)
    end

    child_class = Class.new(parent_class) do
      column(:group_id)
    end

    parent = parent_class.new
    child = child_class.new

    parent.column_by_name(:name).should_not be_nil
    parent.column_by_name(:group_id).should be_nil
    child.column_by_name(:name).should_not be_nil
    child.column_by_name(:group_id).should_not be_nil
  end

end
