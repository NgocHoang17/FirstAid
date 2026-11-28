import { useState } from 'react';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';
import library from '../../mobile/assets/content/reference_library.json';
import { ArticleFields } from './ArticleFields';
import { ArticlePreview } from './ArticlePreview';
import { illustrationCatalogue, StepIllustration } from './StepIllustration';
import type { Article, Category, Source, Step } from './models';

const child = library.articles.find(a => a.category_code === 'FA02' && a.age_group === 'CHILD')! as Article;

describe('bundled step illustrations', () => {
  it('renders every mobile diagram, and keeps the AED in the continuation step', () => {
    const { unmount } = render(<>{illustrationCatalogue.map(d => <StepIllustration key={d.assetKey} step={{ asset_key: d.assetKey, alt_text: d.caption } as Step}/>)}</>);
    expect(screen.getAllByRole('img')).toHaveLength(illustrationCatalogue.length);
    expect(screen.queryByRole('status')).not.toBeInTheDocument();
    unmount();
    const { container } = render(<ArticlePreview article={child} sources={library.sources as Source[]}/>);
    const steps = container.querySelectorAll('.preview-step');
    expect(within(steps[2] as HTMLElement).getByRole('img')).toHaveAccessibleName(/100–120/);
    expect(within(steps[3] as HTMLElement).getByRole('img')).toHaveAccessibleName(/^AED\./);
    expect(within(steps[2] as HTMLElement).queryByText('AED')).not.toBeInTheDocument();
  });

  it('selects a shipped illustration and its text alternative together, and can remove it', async () => {
    const user = userEvent.setup();
    function Editor() {
      const [article, change] = useState(child);
      return <ArticleFields article={article} categories={library.categories as Category[]} sources={library.sources as Source[]} change={change}/>;
    }
    render(<Editor/>);
    const select = screen.getByLabelText('Minh họa bước 3');
    await user.selectOptions(select, 'assets/illustrations/aed.json');
    const editor = select.closest('.step-editor') as HTMLElement;
    expect(within(editor).getByRole('img')).toHaveAccessibleName(/^AED\./);
    expect(within(editor).getByLabelText('Mô tả hình')).toHaveValue(illustrationCatalogue.find(d => d.kind === 'aed')!.caption);
    await user.selectOptions(select, '');
    expect(within(editor).queryByRole('img')).not.toBeInTheDocument();
    expect(within(editor).getByLabelText('Mô tả hình')).toHaveValue('');
  });

  it('reports an unsupported asset without loading an arbitrary path', () => {
    render(<StepIllustration step={{ asset_key: '../../secrets.json' } as Step}/>);
    expect(screen.getByRole('status')).toHaveTextContent('Không tìm thấy hình');
    expect(screen.queryByRole('img')).not.toBeInTheDocument();
  });
});
