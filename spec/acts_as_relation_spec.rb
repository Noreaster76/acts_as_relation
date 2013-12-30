require 'spec_helper'

describe 'submodel' do

  context 'with a pen with a name, price, and color' do
    let!(:pen) { Pen.create name: 'RedPen', price: 0.8, color: 'red' }
    let(:store) { Store.create name: 'Big Store' }

    it 'inherits supermodel attributes' do
      pen = Pen.new
      [
        'name',
        'name=',
        'name_changed?',
        'name_was',
        'price',
        'price=',
        'price_changed?',
        'price_was'
      ].each do |m|
        pen.should respond_to(m)
      end
    end

    it 'has the correct name' do
      pen.name.should  == 'RedPen'
    end

    it 'has the correct price' do
      pen.price.should == 0.8
    end

    it 'has the correct color' do
      pen.color.should == 'red'
    end

    it 'inherits the supermodel parent method' do
      pen.parent_method.should == 'RedPen - 0.8'
    end

    context 'when the price has been changed' do
      before { pen.price = 0.9 }

      it 'indicates that the price has been changed' do
        pen.price_changed?.should be_true
      end

      it 'has the correct value for the previous value of the price' do
        pen.price_was.should == 0.8
      end
    end

    it 'has been successfully persisted' do
      Pen.find(pen.id).should_not be_nil
    end

    describe 'auto_join' do
      let!(:pen_2) { Pen.create name: 'RedPen2', price: 1.2, color: 'red' }
      let!(:blue_pen) { Pen.create name: 'BluePen', price: 1.2, color: 'blue' }
      it 'allows querying on a supermodel attribute' do
        Pen.where('price > 1').should =~ [ pen_2, blue_pen ]
      end

      it 'allows querying on a submodel attribute' do
        Pen.where('name = ?', 'RedPen').should == pen
      end

      it 'can be disabled by setting auto_join option to false' do
        lambda { Pencil.where('name = 1').to_a }.should raise_error(ActiveRecord::StatementInvalid)
      end
    end

    context 'when the pen has a store set' do
      before do
        pen.store = store
        pen.save
      end
      it 'inherits the associated store from the supermodel' do
        Pen.find(pen.id).store.should == store
      end

      it 'inherits the associated store via the product' do
        Pen.find(pen.id).product.store.should == store
      end
    end

    context 'when an non-existent method is called' do
      it 'raises a NoMethodError' do
        lambda { pen.unexisted_method }.should raise_error(NoMethodError)
      end
    end

    context 'when #destroy is called' do
      it 'destroys the supermodel' do
        expect {
          pen.destroy
        }.to change { Product.count }.from(1).to(0)
      end
    end
  end

  context 'a pen with blank attributes' do
    let(:pen) { Pen.new }

    it 'is not valid' do
      pen.should be_invalid
    end

    it 'has an error on name' do
      pen.valid?
      pen.errors[:name].should_not be_empty
    end

    it 'has an error on price' do
      pen.valid?
      pen.errors[:price].should_not be_empty
    end

    it 'has an error on color' do
      pen.valid?
      pen.errors[:color].should_not be_empty
    end
  end

  describe '#acts_as_other_model?' do
    it 'return true on models wich acts_as other ones' do
      Pen.acts_as_other_model?.should be_true
    end
  end

  describe '#acts_as_model_name' do
    it 'returns name of model wich it acts as' do
      Pen.acts_as_model_name.should == :product
    end
  end

  it 'inherits the accessible attributes from the supermodel' do
    if defined?(::ProtectedAttributes)
      Pen.attr_accessible[:default].each do |a|
        Pencil.attr_accessible[:default].should include(a)
      end
    end
  end

end

describe 'supermodel' do
  describe '#specific' do
    let(:pen) { Pen.create name: 'RedPen', price: 0.8, color: 'red' }
    it 'returns the specific subclass object' do
      pen.product.specific.should == pen
    end
  end
end
